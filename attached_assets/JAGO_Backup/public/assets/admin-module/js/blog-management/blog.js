"use strict";

$(document).ready(function () {
    const $summernote = $('#blogDescription');
    const initialContent = $summernote.val();

    $('#blogDescription').summernote({
        placeholder: 'Write a short description of the blog',
        tabsize: 2,
        height: 200,
        toolbar: [
            ['style', ['style']],
            ['font', ['bold', 'underline', 'clear']],
            ['color', ['color']],
            ['para', ['ul', 'ol', 'paragraph']],
            ['table', ['table']],
            ['insert', ['link', 'picture']],
            ['view', ['fullscreen', 'codeview', 'help']]
        ],
        callbacks: {
            onImageUpload: function (files) {
                uploadImage(files[0]);
            }
        }
    });

    $('form').on('reset', function() {
        setTimeout(() => {
            $summernote.summernote('code', initialContent)
        }, 0);
    });

    $('#category-store-or-update').on('submit', function (e) {
        e.preventDefault();
        let formData = $(this).serialize();
        $(this).find('button[type="submit"]').prop('disabled', true);

        $.ajax({
            url: $(this).attr('action'),
            type: 'POST',
            data: formData,
            success: function (response) {
                if (response?.success) {
                    toastr.success(response.message);
                    $('#category-store-or-update').find('#blog_category_name').val('');
                    $('#category-store-or-update').find('#blog_category_id').val('');

                    $.ajax({
                        url: $('.blog-data-to-js').data('category-index-route'),
                        type: 'GET',
                        success: function (response) {
                            console.log(response)
                            $('#blog-category-list').empty().html(response.view);
                            $('#active-categories').empty().html(response.create_blade_category_view)
                        },
                        error: function () {
                            toastr.error("Something went wrong");
                        }
                    });
                } else {
                    for (let index = 0; index < response?.errors.length; index++) {
                        setTimeout(() => {
                            toastr.error(response.errors[index].message);
                        }, index * 1000);
                    }
                }
            },
            error: function (xhr) {
                toastr.error('Something went wrong!');
            },
            complete: function () {
                $('#category-store-or-update button[type="submit"]').prop('disabled', false);
                $('#category-store-or-update button[type="submit"]').text('Submit');
                $('#category-store-or-update button[type="reset"]').text('Reset');
                $('.offcanvas-form-title').text($('.blog-data-to-js').data('offcanvas-create-form-title'));
            }
        });
    });
    $(document).off('click', '.edit-blog-category').on('click', '.edit-blog-category', function (e) {
        e.preventDefault();
        $('#category-store-or-update').find('#blog_category_name').val($(this).data('name'));
        $('#category-store-or-update').find('#blog_category_id').val($(this).data('id'));
        $('#category-store-or-update button[type="submit"]').text('Update');
        $('#category-store-or-update button[type="reset"]').text('Cancel');
        $('.offcanvas-form-title').text($('.blog-data-to-js').data('offcanvas-update-form-title'));
    });
    $(document).off('click', '#category-store-or-update button[type="reset"]').on('click', '#category-store-or-update button[type="reset"]', function (e) {
        e.preventDefault();
        $('#category-store-or-update').find('#blog_category_name').val('');
        $('#category-store-or-update').find('#blog_category_id').val('');
        $('#category-store-or-update button[type="submit"]').text('Submit');
        $('#category-store-or-update button[type="reset"]').text('Reset');
        $('.offcanvas-form-title').text($('.blog-data-to-js').data('offcanvas-create-form-title'));
    });
    $('.search-form-blog-category').on('submit', function (e) {
        e.preventDefault();
        let search = $(this).find('input[name="search"]').val();
        $.ajax({
            url: $('.blog-data-to-js').data('category-index-route'),
            data: {
                search
            },
            type: 'GET',
            success: function (response) {
                $('#blog-category-list').empty().html(response.view);
            },
            error: function () {
                toastr.error("Something went wrong");
            }
        });
    })
});

function uploadImage(file) {
    let data = new FormData();
    data.append('image', file);
    data.append('_token', $('.blog-data-to-js').data('csrf-token'));

    $.ajax({
        url: $('.blog-data-to-js').data('upload-summernote-image-route'),
        method: 'POST',
        data: data,
        contentType: false,
        processData: false,
        success: function (url) {
            $('#blogDescription').summernote('insertImage', url);
        },
        error: function (xhr) {
            if (xhr.status === 413) {
                toastr.error('File is too large. Please upload a smaller file.');
            } else if (xhr?.responseJSON?.errors) {
                xhr?.responseJSON?.errors.forEach((error) => {
                    toastr.error(error.message);
                });
            } else {
                toastr.error('Upload failed.');
            }
        }
    });
}
