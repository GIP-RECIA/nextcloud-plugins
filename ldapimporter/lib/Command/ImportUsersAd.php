<?php

declare(strict_types=1);

namespace OCA\LdapImporter\Command;

use OC\Core\Command\Base;
use OCA\LdapImporter\Service\Import\AdImporter;
use OCP\IAppConfig;
use OCP\IDBConnection;
use OCP\IUserManager;
use Symfony\Component\Console\Helper\ProgressBar;
use Symfony\Component\Console\Input\ArrayInput;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Logger\ConsoleLogger;
use Symfony\Component\Console\Output\OutputInterface;

class ImportUsersAd extends Base
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
            ->setName('ldap:import-users-ad')
            ->setDescription('Imports users from an ActiveDirectory LDAP.')
            ->addOption(
                'delta-update',
                'd',
                InputOption::VALUE_OPTIONAL,
                'Activate updates on existing accounts'
            )
            ->addOption(
                'convert-backend',
                'c',
                InputOption::VALUE_OPTIONAL,
                'Convert the backend to CAS (on update only)'
            )
            ->addOption(
                'ldap-filter',
                'lf',
                InputOption::VALUE_OPTIONAL,
                'filter ldap search'
            );
        parent::configure();
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        try {
            $logger = new ConsoleLogger($output);

            # Check for ldap extension
            if (extension_loaded("ldap")) {

                $output->writeln('Start account import from ActiveDirectory.');

                $importer = new AdImporter(
                    $this->appConfig,
                    $this->dbConnection,
                    $input->getOption('ldap-filter')
                );
                $output->writeln('Construct done');

                $importer->init($logger);
                $output->writeln('init done');

                $allUsers = $importer->getUsers();

                $importer->close();

                $output->writeln('Account import from ActiveDirectory finished.');

                #$importer->exportAsCsv($allUsers);
                #$importer->exportAsText($allUsers);
                #exit;

                $output->writeln('Start account import to database.');

                $progressBar = new ProgressBar($output, count($allUsers));

                # Convert backend
                $convertBackend = $input->getOption('convert-backend');

                if ($convertBackend) {
                    $logger->info("Backend conversion: Backends will be converted to CAS-Backend.");
                }

                # Delta Update
                $deltaUpdate = $input->getOption('delta-update');

                if ($deltaUpdate) {
                    $logger->info("Delta updates: Existing users will be updated.");
                }

                $createCommand = $this->getApplication()->find('ldap:create-user');
                $updateCommand = $this->getApplication()->find('ldap:update-user');

                foreach ($allUsers as $user) {
                    $arguments = [
                        'command' => 'ldap:create-user',
                        'uid' => $user["uid"],
                        '--display-name' => $user["displayName"],
                        '--email' => $user["email"],
                        '--quota' => $user["quota"] . "GB",
                        '--enabled' => $user["enable"],
                        '--group' => $user["groups"]
                    ];

                    # Create user if he does not exist
                    if (!$this->userManager->userExists($user["uid"])) {
                        $logger->info(" " . implode(',', array_slice($arguments, 0,  6)) . "[" . implode(', ', $user["groups"]) . ']');
                        $input = new ArrayInput($arguments);
                        $createCommand->run($input, $output);
                    } # Update user if he already exists and delta update is true
                    else if ($this->userManager->userExists($user["uid"]) && $deltaUpdate) {
                        $arguments['command'] = 'ldap:update-user';
                        $logger->info(" " . implode(',', array_slice($arguments, 0, 6)) . "[" . implode(', ', $user["groups"]) . ']');

                        if ($convertBackend) {
                            $arguments["--convert-backend"] = 1;
                        }
                        $input = new ArrayInput($arguments);
                        $updateCommand->run($input, $output);
                    }

                    $progressBar->advance();
                }

                $progressBar->finish();
                $progressBar->clear();

                $output->writeln('Account import to database finished.');
            } else {
                throw new \Exception("User import failed. PHP extension 'ldap' is not loaded.");
            }
        } catch (\Exception $e) {
            $logger->critical("Fatal Error: " . $e->getMessage());
            return 1;
        }

        return 0;
    }
}
