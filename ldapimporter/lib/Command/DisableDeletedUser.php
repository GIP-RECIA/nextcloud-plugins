<?php

declare(strict_types=1);

namespace OCA\LdapImporter\Command;

use OC\Core\Command\Base;
use OCA\LdapImporter\Service\Delete\DeleteService;
use OCP\IAppConfig;
use OCP\IDBConnection;
use OCP\IUserManager;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Logger\ConsoleLogger;
use Symfony\Component\Console\Output\OutputInterface;

class DisableDeletedUser extends Base
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
            ->setName('ldap:disable-deleted-user')
            ->setDescription('Disable users that not in ldap anymore')
            ->addOption(
                'uai',
                null,
                InputOption::VALUE_OPTIONAL,
                'Liste des UAI des établissements séparer par des virgules'
            )
            ->addOption(
                'siren',
                's',
                InputOption::VALUE_OPTIONAL,
                'Liste des UAI des établissements séparer par des virgules'
            )
            ->addOption(
                'users',
                'u',
                InputOption::VALUE_OPTIONAL,
                'Liste des utilsateurs à supprimer séparé par des virgules'
            );
        parent::configure();
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        try {
            $logger = new ConsoleLogger($output);

            $output->writeln('Start disable deleted user.');

            $deleteService = new DeleteService(
                $this->appConfig,
                $this->dbConnection,
                $this->userManager
            );
            $output->writeln('Construct done');

            $deleteService->init($logger);
            $output->writeln('init done');

            $uai = $input->getOption('uai');
            $siren = $input->getOption('siren');
            $users = $input->getOption('users');
            if (!is_null($uai)) {
                $uai = explode(",", $input->getOption('uai'));
            }
            if (!is_null($siren)) {
                $siren = explode(",", $input->getOption('siren'));
            }
            if (!is_null($users)) {
                $users = explode(",", $input->getOption('users'));
            }
            $deleteService->disableDeletedUsers($uai, $siren, $users);
            $deleteService->close();
            $output->writeln('Disabling users finished.');
        } catch (\Exception $e) {
            $logger->critical("Fatal Error: " . $e->getMessage());
        }

        return 0;
    }
}
