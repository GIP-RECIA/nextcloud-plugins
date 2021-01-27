<?php


namespace OCA\LdapImporter\Command;

use OC\User\Manager;
use OCA\LdapImporter\Service\Delete\DeleteService;
use OCA\LdapImporter\Service\Import\AdImporter;
use OCA\LdapImporter\Service\Import\ImporterInterface;
use OCP\IConfig;
use OCP\IDBConnection;
use OCP\IGroupManager;
use OCP\IUserManager;
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
 * Class DisableDeletedUser
 * @package OCA\LdapImporter\Command
 *
 */
class DisableDeletedUser extends Command
{

    /**
     * @var IConfig
     */
    private $config;

    /**
     * @var IDBConnection
     */
    private $db;

    /**
     * @var IGroupManager
     */
    private $groupManager;

    /**
     * @var IUserManager
     */
    private $userManager;

    /**
     * ImportUsersAd constructor.
     * @param IDBConnection $db
     * @param IGroupManager $groupManager
     * @param IUserManager $userManager
     */
    public function __construct(IDBConnection $db, IGroupManager $groupManager, IUserManager $userManager)
    {
        parent::__construct();

        $this->userManager = \OC::$server->getUserManager();
        $this->config = \OC::$server->getConfig();
        $this->db = $db;
        $this->groupManager = $groupManager;
        $this->userManager = $userManager;

    }

    /**
     * Configure method
     */
    protected function configure()
    {
        $this
            ->setName('ldap:disable-deleted-user')
            ->setDescription('Disable users that not in ldap anymore')
            ->setDescription('UAI des établissements séléctionnés')
            ->addOption(
                'uai',
                'uai',
                InputOption::VALUE_OPTIONAL,
                'Liste des UAI des établissements séparer par des virgules'
            )
            ->setDescription('Siren des établissements séléctionnés')
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

            $output->writeln('Start disable deleted user.');

            $importer = new DeleteService($this->config, $this->db, $this->groupManager, $this->userManager);
            $output->writeln('Construct done');

            $importer->init($logger);
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
            $importer->disableDeletedUsers($uai, $siren, $users);

            $importer->close();

            $output->writeln('Disabling users finished.');

        } catch (\Exception $e) {
            $logger->critical("Fatal Error: " . $e->getMessage());
        }
    }
}
