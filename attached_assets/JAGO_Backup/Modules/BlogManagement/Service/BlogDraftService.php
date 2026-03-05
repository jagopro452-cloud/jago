<?php

namespace Modules\BlogManagement\Service;


use App\Service\BaseService;

use Modules\BlogManagement\Repository\BlogDraftRepositoryInterface;
use Modules\BlogManagement\Service\Interfaces\BlogDraftServiceInterface;

class BlogDraftService extends BaseService implements BlogDraftServiceInterface
{
    protected $blogDraftRepository;

    public function __construct(BlogDraftRepositoryInterface $blogDraftRepository)
    {
        parent::__construct($blogDraftRepository);
        $this->blogDraftRepository = $blogDraftRepository;
    }

    public function saveBlogDraft(array $data): void
    {
        if (array_key_exists('thumbnail', $data)) {
            $fileName = fileUploader('blog/', APPLICATION_IMAGE_FORMAT, $data['thumbnail'], $data['blogDraft']?->thumbnail ?? '');
            $data['thumbnail'] = $fileName;
        } else {
            $data['thumbnail'] = $data['blogDraft']->thumbnail ?? '';
        }

        if (array_key_exists('is_published', $data)) {
            $data['status'] = 1;
            $data['blogDraft']->blog->update($data);
            $data['blogDraft']->delete();
        } else {
            $data['blogDraft']->update($data);
        }
    }
}
