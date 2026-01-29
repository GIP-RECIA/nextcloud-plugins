<?php

namespace OCA\LdapImporter\Command;

use OC\Core\Command\Base;
use OCA\LdapImporter\Service\Delete\DeleteService;
use OCP\IAppConfig;
use OCP\IDBConnection;
use OCP\IUserManager;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Logger\ConsoleLogger;
use Symfony\Component\Console\Output\OutputInterface;

class RemoveDisabledUser extends Base
{
    public function __construct(
        private IAppConfig $appConfig,
        private IDBConnection $dbConnection,
        private IUserManager $userManager
    ) {
        parent::__construct();
    }

    protected function configure()
    {
        $this
            ->setName('ldap:remove-disabled-user')
            ->setDescription('Remove disabled users');
        parent::configure();
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        try {
            $logger = new ConsoleLogger($output);

            $deleteService = new DeleteService(
                $this->appConfig,
                $this->dbConnection,
                $this->userManager
            );
            $output->writeln('Construct done');

            $deleteService->init($logger);
            $output->writeln('init done');

            $output->writeln('Start removing disable users');
            $deleteService->removedDisabledUsers();
            $deleteService->close();

            $output->writeln('Disabling users finished.');
        } catch (\Exception $e) {
            $logger->critical("Fatal Error: " . $e->getMessage());
        }

        return 0;
    }
}
