<?php

namespace Modules\UserManagement\Service;


use App\Service\BaseService;
use Modules\UserManagement\Repository\UserRepositoryInterface;
use Modules\UserManagement\Service\Interfaces\UserServiceInterface;

class UserService extends BaseService implements UserServiceInterface
{
    protected $userRepository;

    public function __construct(UserRepositoryInterface $userRepository)
    {
        parent::__construct($userRepository);
        $this->userRepository = $userRepository;
    }

    // Add your specific methods related to UserService here
}
