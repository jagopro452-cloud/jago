<?php

namespace Modules\BlogManagement\Service;


use App\Service\BaseService;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Pagination\LengthAwarePaginator;
use Modules\BlogManagement\Repository\BlogDraftRepositoryInterface;
use Modules\BlogManagement\Repository\BlogRepositoryInterface;
use Modules\BlogManagement\Service\Interfaces\BlogServiceInterface;

class BlogService extends BaseService implements BlogServiceInterface
{
    protected $blogRepository;
    protected $blogDraftRepository;

    public function __construct(BlogRepositoryInterface $blogRepository, BlogDraftRepositoryInterface $blogDraftRepository)
    {
        parent::__construct($blogRepository);
        $this->blogRepository = $blogRepository;
        $this->blogDraftRepository = $blogDraftRepository;
    }

    public function index(array $criteria = [], array $relations = [], array $whereHasRelations = [], array $orderBy = [], ?int $limit = null, ?int $offset = null, array $withCountQuery = [], array $appends = [], array $groupBy = []): Collection|LengthAwarePaginator
    {
        $data = [];
        $searchData = [];

        if (array_key_exists('search', $criteria) && $criteria['search'] != '') {
            $searchData['fields'] = ['title'];
            $searchData['relations'] = [
                'category' => ['name'],
            ];
            $searchData['value'] = $criteria['search'];
        }

        $whereBetweenCriteria = [];
        if (array_key_exists('filter_date', $criteria)) {
            $whereBetweenCriteria = ['published_at' => $criteria['filter_date']];
        }

        if (array_key_exists('blog_category_id', $criteria) && !empty($criteria['blog_category_id']))
        {
            $data = ['blog_category_id' => $criteria['blog_category_id']];
        }

        return $this->blogRepository->getBy(criteria: $data, searchCriteria: $searchData, whereInCriteria: $whereInCriteria ?? [], whereBetweenCriteria: $whereBetweenCriteria, whereHasRelations: $whereHasRelations, relations: $relations, orderBy: $orderBy, limit: $limit, offset: $offset, withCountQuery: $withCountQuery, appends: $appends, groupBy: $groupBy);

    }

    public function saveBlog(array $data): void
    {
        if (array_key_exists('blog', $data)) {
            $blog = $data['blog'];
        }

        if (array_key_exists('thumbnail', $data)) {
            $fileName = fileUploader('blog/', APPLICATION_IMAGE_FORMAT, $data['thumbnail'],  $blog?->thumbnail ?? '');
            $data['thumbnail'] = $fileName;
        } else {
            $data['thumbnail'] = $blog->thumbnail ?? '';
        }

        if (array_key_exists('meta_image', $data)) {
            $fileName = fileUploader('blog/meta-image/', APPLICATION_IMAGE_FORMAT, $data['meta_image'], $blog?->meta_image ?? '');
            $data['meta_image'] = $fileName;
        } else {
            $data['meta_image'] = $blog->meta_image ?? '';
        }

        if (array_key_exists('blog', $data)) {
            if (array_key_exists('is_published', $data)) {
                $data['status'] = 1;

                $blog->update($data);
                if ($blog?->draft)
                {
                    $blog->draft->delete();
                }
            }
        } else {
            if (array_key_exists('is_drafted', $data)) {
                $data['status'] = 0;
            }

            $blog = $this->blogRepository->create(data: $data);
        }

        if (array_key_exists('is_drafted', $data)) {
            if (isset($blog) && $blog->draft) {
                $blog->draft->update($data);
            } else {
                $this->blogDraftRepository->create(data: array_merge($data, ['blog_id' => $blog->id]));
            }
        }
    }

    public function export(Collection $data): Collection|LengthAwarePaginator|\Illuminate\Support\Collection
    {
        return $data->map(function ($item) {
            $source = $item->is_published ? $item : $item->draft;
            return [
                'Id' => $item['readable_id'],
                'Category' => $source?->category?->name ?? 'N/A',
                'Title' => $source?->title ?? 'N/A',
                'Writer' => $source?->writer ?? 'N/A',
                'Publish Date' => $source?->published_at?->format('d M, Y') ?? 'N/A',
                'Status' => $item->status == 0 ? translate('inactive') : translate('Active'),
            ];
        });
    }

    public function search(array $criteria = [], array $relations = [], array $whereHasRelations = [], array $orderBy = [], ?int $limit = null, ?int $offset = null, array $withCountQuery = [], array $appends = [], array $groupBy = []): Collection|LengthAwarePaginator
    {
        $searchData = [];

        if (array_key_exists('search', $criteria) && $criteria['search'] != '') {
            $searchData['fields'] = ['title'];
            $searchData['relations'] = [
                'category' => ['name'],
            ];
            $searchData['value'] = $criteria['search'];
        }
        unset($criteria['search']);
        $data = $criteria;
        $whereBetweenCriteria = [];

        return $this->blogRepository->getBy(criteria: $data, searchCriteria: $searchData, whereInCriteria: $whereInCriteria ?? [], whereBetweenCriteria: $whereBetweenCriteria, whereHasRelations: $whereHasRelations, relations: $relations, orderBy: $orderBy, limit: $limit, offset: $offset, withCountQuery: $withCountQuery, appends: $appends, groupBy: $groupBy);
    }

}
