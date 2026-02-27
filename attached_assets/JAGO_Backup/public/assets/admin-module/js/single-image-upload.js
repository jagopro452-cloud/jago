document.querySelectorAll(".upload-file__input").forEach(function (input) {
    input.addEventListener("change", function (event) {
        const card = event.target.closest(".upload-file");
        const textbox = card.querySelector(".upload-file__textbox");
        const imgElement = card.querySelector(".upload-file__img__img");
        const removeIcon = card.querySelector(".remove-img-icon");
        const prevSrc = textbox.querySelector("img").src;

        const newFile = input.files[0];
        if (!newFile) return;

        let prevFileSize = input.dataset.prevSize ? parseInt(input.dataset.prevSize) : 0;

        const newTotal = totalSize - prevFileSize + newFile.size;

        if (newTotal > postMaxSize) {
            toastr.error(
                `Total uploaded file size exceeds ${$('.image-file-size-data-to-js').data('post-max-size')} MB. Please remove some files.`,
                { CloseButton: true, ProgressBar: true }
            );
            input.value = "";
            return;
        }

        totalSize = newTotal;
        input.dataset.prevSize = newFile.size;

        const reader = new FileReader();
        reader.onload = function (e) {
            imgElement.src = e.target.result;
            imgElement.style.display = "block";
            textbox.style.display = "none";
            removeIcon.classList.remove("d-none");
        };
        reader.readAsDataURL(newFile);

        removeIcon.onclick = function () {
            if (input.dataset.prevSize) {
                totalSize -= parseInt(input.dataset.prevSize);
            }
            input.value = "";
            input.removeAttribute("data-prev-size");
            imgElement.src = "";
            imgElement.style.display = "none";
            textbox.style.display = "block";
            textbox.querySelector("img").src = prevSrc;
            removeIcon.classList.add("d-none");
        };
    });
});

document.querySelectorAll("form").forEach(function (form) {
    form.addEventListener("reset", function () {
        setTimeout(function () {
            form.querySelectorAll(".upload-file").forEach(function (card) {
                const input = card.querySelector(".upload-file__input");
                const previewImg = card.querySelector(".upload-file__img__img");
                const textbox = card.querySelector(".upload-file__textbox");
                const removeIcon = card.querySelector(".remove-img-icon");

                input.value = "";

                if (previewImg.dataset.original && previewImg.dataset.original.trim() !== "") {
                    previewImg.src = previewImg.dataset.original;
                    previewImg.style.display = "block";
                    textbox.style.display = "none";
                } else {
                    previewImg.src = "";
                    previewImg.style.display = "none";
                    textbox.style.display = "block";
                }

                removeIcon.classList.add("d-none");
            });
        }, 0);
    });
});


