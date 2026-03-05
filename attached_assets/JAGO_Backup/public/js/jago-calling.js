const JagoCalling = (function() {
    let peerConnection = null;
    let localStream = null;
    let mediaRecorder = null;
    let recordedChunks = [];
    let currentCallId = null;
    let currentUserId = null;
    let currentUserType = null;
    let pollInterval = null;
    let incomingPollInterval = null;
    let callTimer = null;
    let callSeconds = 0;
    let onCallStateChange = null;
    let onIncomingCall = null;
    let ringtoneAudio = null;

    const ICE_SERVERS = [
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' },
        { urls: 'stun:stun2.l.google.com:19302' }
    ];

    function init(config) {
        currentUserId = config.userId;
        currentUserType = config.userType;
        onCallStateChange = config.onCallStateChange || function() {};
        onIncomingCall = config.onIncomingCall || function() {};

        startIncomingPoll();
    }

    function startIncomingPoll() {
        if (incomingPollInterval) clearInterval(incomingPollInterval);
        incomingPollInterval = setInterval(async () => {
            if (currentCallId) return;
            try {
                const resp = await fetch(`/api/calls/incoming?user_id=${currentUserId}`);
                const data = await resp.json();
                if (data.incoming) {
                    onIncomingCall(data.incoming);
                }
            } catch(e) {}
        }, 3000);
    }

    function stopIncomingPoll() {
        if (incomingPollInterval) {
            clearInterval(incomingPollInterval);
            incomingPollInterval = null;
        }
    }

    async function startCall(tripRequestId, calleeType, calleeId) {
        try {
            onCallStateChange('connecting', { message: 'Starting call...' });

            const resp = await fetch('/api/calls/start', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    trip_request_id: tripRequestId,
                    caller_type: currentUserType,
                    caller_id: currentUserId,
                    callee_type: calleeType,
                    callee_id: calleeId,
                })
            });

            const data = await resp.json();
            if (!resp.ok) {
                onCallStateChange('error', { message: data.error || 'Failed to start call' });
                return false;
            }

            currentCallId = data.call_id;

            localStream = await navigator.mediaDevices.getUserMedia({ audio: true, video: false });

            createPeerConnection();

            const offer = await peerConnection.createOffer();
            await peerConnection.setLocalDescription(offer);

            await sendSignal('offer', { sdp: offer.sdp, type: offer.type });

            startRecording();
            startPolling();

            onCallStateChange('ringing', { callId: currentCallId });

            return true;
        } catch(e) {
            console.error('Call start error:', e);
            onCallStateChange('error', { message: e.message || 'Microphone access denied' });
            cleanup();
            return false;
        }
    }

    async function answerCall(callId) {
        try {
            currentCallId = callId;
            onCallStateChange('connecting', { message: 'Answering call...' });

            localStream = await navigator.mediaDevices.getUserMedia({ audio: true, video: false });

            createPeerConnection();
            startPolling();
            startRecording();

            onCallStateChange('answered', { callId: currentCallId });
        } catch(e) {
            console.error('Answer error:', e);
            onCallStateChange('error', { message: e.message || 'Microphone access denied' });
            cleanup();
        }
    }

    async function rejectCall(callId) {
        try {
            await sendSignalDirect(callId, 'reject', { reason: 'rejected' });
            onCallStateChange('ended', { reason: 'rejected' });
        } catch(e) {}
    }

    function createPeerConnection() {
        peerConnection = new RTCPeerConnection({ iceServers: ICE_SERVERS });

        localStream.getTracks().forEach(track => {
            peerConnection.addTrack(track, localStream);
        });

        peerConnection.onicecandidate = (event) => {
            if (event.candidate) {
                sendSignal('ice', { candidate: event.candidate.toJSON() });
            }
        };

        peerConnection.ontrack = (event) => {
            const remoteAudio = document.getElementById('jago-remote-audio') || createRemoteAudio();
            remoteAudio.srcObject = event.streams[0];
            remoteAudio.play().catch(() => {});

            onCallStateChange('connected', { callId: currentCallId });
            startCallTimer();
        };

        peerConnection.onconnectionstatechange = () => {
            if (peerConnection.connectionState === 'disconnected' ||
                peerConnection.connectionState === 'failed') {
                endCall();
            }
        };
    }

    function createRemoteAudio() {
        let audio = document.createElement('audio');
        audio.id = 'jago-remote-audio';
        audio.autoplay = true;
        audio.style.display = 'none';
        document.body.appendChild(audio);
        return audio;
    }

    function startRecording() {
        try {
            recordedChunks = [];
            const combinedStream = new MediaStream();

            localStream.getAudioTracks().forEach(t => combinedStream.addTrack(t));

            mediaRecorder = new MediaRecorder(combinedStream, { mimeType: 'audio/webm;codecs=opus' });
            mediaRecorder.ondataavailable = (e) => {
                if (e.data.size > 0) recordedChunks.push(e.data);
            };
            mediaRecorder.start(1000);
        } catch(e) {
            console.warn('Recording not supported:', e);
        }
    }

    async function uploadRecording() {
        if (!recordedChunks.length || !currentCallId) return;

        try {
            const blob = new Blob(recordedChunks, { type: 'audio/webm' });
            const formData = new FormData();
            formData.append('recording', blob, `call_${currentCallId}.webm`);
            formData.append('user_type', currentUserType);
            formData.append('user_id', currentUserId);
            formData.append('duration_seconds', callSeconds);

            await fetch(`/api/calls/${currentCallId}/recording`, {
                method: 'POST',
                body: formData,
            });
        } catch(e) {
            console.error('Upload recording error:', e);
        }
    }

    async function sendSignal(type, payload) {
        if (!currentCallId) return;
        return sendSignalDirect(currentCallId, type, payload);
    }

    async function sendSignalDirect(callId, type, payload) {
        await fetch(`/api/calls/${callId}/signal`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                sender_type: currentUserType,
                sender_id: currentUserId,
                signal_type: type,
                payload: payload,
            })
        });
    }

    function startPolling() {
        if (pollInterval) clearInterval(pollInterval);
        pollInterval = setInterval(async () => {
            if (!currentCallId) return;
            try {
                const resp = await fetch(`/api/calls/${currentCallId}/poll?user_id=${currentUserId}`);
                const data = await resp.json();

                if (data.call_status === 'ended' || data.call_status === 'rejected' || data.call_status === 'failed') {
                    onCallStateChange('ended', { reason: data.call_status });
                    cleanup();
                    return;
                }

                for (const signal of data.signals) {
                    await handleSignal(signal);
                }
            } catch(e) {}
        }, 1500);
    }

    async function handleSignal(signal) {
        if (!peerConnection) return;

        switch(signal.signal_type) {
            case 'offer':
                await peerConnection.setRemoteDescription(new RTCSessionDescription({
                    sdp: signal.payload.sdp,
                    type: signal.payload.type,
                }));
                const answer = await peerConnection.createAnswer();
                await peerConnection.setLocalDescription(answer);
                await sendSignal('answer', { sdp: answer.sdp, type: answer.type });
                break;

            case 'answer':
                await peerConnection.setRemoteDescription(new RTCSessionDescription({
                    sdp: signal.payload.sdp,
                    type: signal.payload.type,
                }));
                break;

            case 'ice':
                if (signal.payload.candidate) {
                    await peerConnection.addIceCandidate(new RTCIceCandidate(signal.payload.candidate));
                }
                break;

            case 'bye':
            case 'reject':
                onCallStateChange('ended', { reason: signal.signal_type });
                cleanup();
                break;
        }
    }

    function startCallTimer() {
        callSeconds = 0;
        if (callTimer) clearInterval(callTimer);
        callTimer = setInterval(() => {
            callSeconds++;
            const mins = Math.floor(callSeconds / 60).toString().padStart(2, '0');
            const secs = (callSeconds % 60).toString().padStart(2, '0');
            onCallStateChange('timer', { time: `${mins}:${secs}`, seconds: callSeconds });
        }, 1000);
    }

    async function endCall() {
        if (!currentCallId) return;

        try {
            await sendSignal('bye', { reason: 'hangup' });
        } catch(e) {}

        if (mediaRecorder && mediaRecorder.state !== 'inactive') {
            mediaRecorder.stop();
            await new Promise(resolve => setTimeout(resolve, 500));
            await uploadRecording();
        }

        onCallStateChange('ended', { reason: 'hangup', duration: callSeconds });
        cleanup();
    }

    function toggleMute() {
        if (localStream) {
            const audioTrack = localStream.getAudioTracks()[0];
            if (audioTrack) {
                audioTrack.enabled = !audioTrack.enabled;
                return !audioTrack.enabled;
            }
        }
        return false;
    }

    function toggleSpeaker() {
        const remoteAudio = document.getElementById('jago-remote-audio');
        if (remoteAudio) {
            if (remoteAudio.volume > 0.5) {
                remoteAudio.volume = 1.0;
            }
        }
    }

    function cleanup() {
        if (pollInterval) { clearInterval(pollInterval); pollInterval = null; }
        if (callTimer) { clearInterval(callTimer); callTimer = null; }

        if (localStream) {
            localStream.getTracks().forEach(t => t.stop());
            localStream = null;
        }

        if (peerConnection) {
            peerConnection.close();
            peerConnection = null;
        }

        if (mediaRecorder && mediaRecorder.state !== 'inactive') {
            mediaRecorder.stop();
        }
        mediaRecorder = null;
        recordedChunks = [];

        const remoteAudio = document.getElementById('jago-remote-audio');
        if (remoteAudio) remoteAudio.remove();

        currentCallId = null;
        callSeconds = 0;

        startIncomingPoll();
    }

    function destroy() {
        cleanup();
        stopIncomingPoll();
    }

    function isInCall() {
        return currentCallId !== null;
    }

    async function callSupport() {
        return startCall('support', 'support', 'support-agent');
    }

    return {
        init,
        startCall,
        answerCall,
        rejectCall,
        endCall,
        toggleMute,
        toggleSpeaker,
        callSupport,
        isInCall,
        destroy,
    };
})();
