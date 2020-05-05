<?php


namespace OCA\LdapImporter\Command;

use OC\User\Manager;
use OCA\LdapImporter\Service\Import\AdImporter;
use OCA\LdapImporter\Service\Import\ImporterInterface;
use OCP\IConfig;
use OCP\IDBConnection;
use Psr\Log\LoggerInterface;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Helper\ProgressBar;
use Symfony\Component\Console\Input\ArrayInput;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Logger\ConsoleLogger;
use Symfony\Component\Console\Output\NullOutput;
use Symfony\Component\Console\Output\OutputInterface;


/**
 * Class ImportUsersAd
 * @package OCA\LdapImporter\Command
 *
 */
class ImportUsersAd extends Command
{

    /**
     * @var Manager $userManager
     */
    private $userManager;

    /**
     * @var IConfig
     */
    private $config;

    /**
     * @var IDBConnection
     */
    private $db;

    /**
     * ImportUsersAd constructor.
     * @param IDBConnection $db
     */
    public function __construct(IDBConnection $db)
    {
        parent::__construct();

        $this->userManager = \OC::$server->getUserManager();
        $this->config = \OC::$server->getConfig();
        $this->db = $db;

    }

    /**
     * Configure method
     */
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
                'Convert the backend to CAS (on update only)')
            ->addOption(
                'ldap-filter',
                'lf',
                InputOption::VALUE_OPTIONAL,
                'filter ldap search'
            )
        ;
    }

    /**
     * Execute method
     *
     * @param InputInterface $input
     * @param OutputInterface $output
     */
    protected function execute(InputInterface $input, OutputInterface $output)
    {


        try {
            /**
             * @var LoggerInterface $logger
             */
            $logger = new ConsoleLogger($output);

            # Check for ldap extension
            if (extension_loaded("ldap")) {

                $output->writeln('Start account import from ActiveDirectory.');

                /**
                 * @var ImporterInterface $importer
                 */
                $importer = new AdImporter($this->config, $this->db, $input->getOption('ldap-filter'));
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
                        '--quota' => $user["quota"]."GB",
                        '--enabled' => $user["enable"],
                        '--group' => $user["groups"]
                    ];

                    # Create user if he does not exist
                    if (!$this->userManager->userExists($user["uid"])) {
$logger->info(" " . implode(',' , array_slice($arguments, 0,  6)). "[" . implode(', ' , $user["groups"]) . ']');

                        $input = new ArrayInput($arguments);

                        $createCommand->run($input, new NullOutput());
                    } # Update user if he already exists and delta update is true
                    else if ($this->userManager->userExists($user["uid"]) && $deltaUpdate) {

                        $arguments['command'] = 'ldap:update-user';
$logger->info(" " . implode(',' , array_slice($arguments, 0, 6)). "[" . implode(', ' , $user["groups"]) . ']');

                        if ($convertBackend) {

                            $arguments["--convert-backend"] = 1;
                        }
                        $input = new ArrayInput($arguments);

                        $updateCommand->run($input, new NullOutput());
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
        }
    }
}
