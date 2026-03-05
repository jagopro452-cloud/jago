const spartanRowSizes = {};

function getTotalUploadedSize() {
    let total = 0;
    $('#multi_image_picker input[type="file"]').each(function() {
        if (this.files && this.files.length > 0) {
            for (const file of this.files) {
                total += file.size;
            }
        }
    });

    $('.upload-file__input').each(function() {
        if (this.files && this.files.length > 0) {
            for (const file of this.files) total += file.size;
        }
    });

    if (typeof newSelectedFiles !== 'undefined') {
        newSelectedFiles.forEach(file => total += file.size);
    }

    return total;
}

document.querySelector('#multi_image_picker').addEventListener(
    'change',
    function (e) {
        if (e.target && e.target.type === 'file') {
            const input = e.target;
            const files = input.files;
            if (!files || !files.length) return;

            const currentTotal = getTotalUploadedSize() - [...files].reduce((sum, f) => sum + f.size, 0);
            const newFilesTotal = [...files].reduce((sum, f) => sum + f.size, 0);
            const newTotal = currentTotal + newFilesTotal;

            if (newTotal > postMaxSize) {
                toastr.error(
                    `Total uploaded file size exceeds ${$('.image-file-size-data-to-js').data('post-max-size')} MB. Please remove some files.`,
                    { CloseButton: true, ProgressBar: true }
                );

                input.value = '';

                const $label = $(input).closest('.file_upload');
                $label.find('.spartan_image_placeholder').show();
                $label.find('#dropAreaLabel').show();
                $label.find('.img_').hide();

                e.stopImmediatePropagation();
                e.preventDefault();
                return false;
            }

            totalSize = newTotal;
        }
    },
    true
);

function setAcceptForAllInputs() {
    const allowedExtensions = $('.image-file-size-data-to-js').data('allowed-extensions');
    $('#multi_image_picker input[type=file]').each(function() {
        $(this).attr('accept', allowedExtensions);
    });
}

// upload multiple images
$("#multi_image_picker").spartanMultiImagePicker({
    fieldName: 'identity_images[]',
    maxCount: 5,
    rowHeight: '130px',
    maxFileSize: parseFloat($('.image-file-size-data-to-js').data('max-upload-size-for-image')) * 1024 * 1024,
    allowedExtensions: $('.image-file-size-data-to-js').data('allowed-extensions').split(',').map(ext => ext.trim().replace(/^\./, '')),
    groupClassName: 'upload-file__img upload-file__img_banner',
    placeholderImage: {
        image: onMultipleImageUploadBaseImage,
        width: '34px',
    },
    dropFileLabel: `
                <h6 id="dropAreaLabel" class="mt-2 fw-semibold">
                    <span class="text-info">${onMultipleImageUploadText1}</span>
                    <br>
                    ${onMultipleImageUploadText2}
            </h6>`,

    onRenderedPreview: function(index) {
        $("#dropAreaLabel").hide();
        setAcceptForAllInputs();
        const $input = $(`#multi_image_picker input[data-spartanindexinput="${index}"]`);
        if ($input.length && $input[0].files.length) {
            spartanRowSizes[index] = $input[0].files[0].size;
        }
        $(".file_upload").on("dragenter input", function(e) {
            e.preventDefault();
            e.stopPropagation();
            $(this).find('#dropAreaLabel').hide();
            $(this).find('.spartan_image_placeholder').hide();
        });

        toastr.success(onMultipleImageUploadSuccess, {
            CloseButton: true,
            ProgressBar: true
        });
    },

    onRemoveRow: function(index) {
        if (spartanRowSizes[index]) {
            totalSize -= spartanRowSizes[index];
            delete spartanRowSizes[index];
        }

        if ($(".file_upload").find(".img_").length === 0) {
            $("#dropAreaLabel").show();
        }
    },

    onExtensionErr: function (index, file) {
        toastr.error(onMultipleImageUploadExtensionError, {
            CloseButton: true,
            ProgressBar: true
        });

        const $currentBox = $(`.file_upload`).eq(index);
        $currentBox.find('.spartan_image_placeholder').show();
        $currentBox.find('#dropAreaLabel').show();
    },

    onSizeErr: function(index, file) {
        toastr.error(onMultipleImageUploadSizeError, {
            CloseButton: true,
            ProgressBar: true
        });
        const $currentBox = $(`.file_upload`).eq(index);
        $currentBox.find('.spartan_image_placeholder').show();
        $currentBox.find('#dropAreaLabel').show();

    }
});
//upload multiple images ends
setAcceptForAllInputs();
