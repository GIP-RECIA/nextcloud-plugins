<?php


namespace OCA\LdapImporter\Command;

use OCA\LdapImporter\Service\Delete\DeleteService;
use OCP\IConfig;
use OCP\IDBConnection;
use OCP\IGroupManager;
use OCP\IUserManager;
use Psr\Log\LoggerInterface;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Logger\ConsoleLogger;
use Symfony\Component\Console\Output\OutputInterface;


/**
 * Class DisableDeletedUser
 * @package OCA\LdapImporter\Command
 *
 */
class RemoveDisabledUser extends Command
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
     * @var IUserManager $userManager
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

        $this->userManager = \OCP\Server::get(IUserManager::class);
        $this->config = \OCP\Server::get(IConfig::class);
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
            ->setName('ldap:remove-disabled-user')
            ->setDescription('Remove disabled users')
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

            $importer = new DeleteService($this->config, $this->db, $this->groupManager, $this->userManager);
            $output->writeln('Construct done');

            $importer->init($logger);
            $output->writeln('init done');

            $output->writeln('Start removing disable users');
            $importer->removedDisabledUsers();

            $importer->close();

            $output->writeln('Disabling users finished.');

        } catch (\Exception $e) {
            $logger->critical("Fatal Error: " . $e->getMessage());
        }
        return 0;
    }
}
