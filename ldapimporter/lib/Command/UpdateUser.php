<?php

namespace OCA\LdapImporter\Command;

use OCA\LdapImporter\Service\AppService;
use OCA\LdapImporter\Service\LoggingService;
use OCA\LdapImporter\Service\UserService;

use OCA\LdapImporter\User\Backend;
use OCA\LdapImporter\User\NextBackend;
use OCA\LdapImporter\User\UserCasBackendInterface;
use OCP\IDBConnection;
use OCP\IGroupManager;
use OCP\IUser;
use OCP\IUserManager;
use OCP\Mail\IMailer;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Input\InputArgument;


/**
 * Class UpdateUser
 *
 * @package OCA\LdapImporter\Command
 *
 * @author Felix Rupp <kontakt@felixrupp.com>
 * @copyright Felix Rupp <kontakt@felixrupp.com>
 *
 * @since 1.7.0
 */
class UpdateUser extends Command
{

    /**
     * @var UserService
     */
    protected $userService;

    /**
     * @var AppService
     */
    protected $appService;

    /**
     * @var IUserManager
     */
    protected $userManager;

    /**
     * @var IGroupManager
     */
    protected $groupManager;

    /**
     * @var IMailer
     */
    protected $mailer;

    /**
     * @var LoggingService
     */
    protected $loggingService;

    /**
     * @var \OCP\IConfig
     */
    protected $config;

    /**
     * @var Backend|UserCasBackendInterface
     */
    protected $backend;

    /**
     * @var IDBConnection
     */
    private $db;

    /**
     * @param IDBConnection $db
     */
    public function __construct(IDBConnection $db)
    {
        parent::__construct();

        $userManager = \OC::$server->getUserManager();
        $groupManager = \OC::$server->getGroupManager();
        $mailer = \OC::$server->getMailer();
        $config = \OC::$server->getConfig();
        $userSession = \OC::$server->getUserSession();
        $logger = \OC::$server->getLogger();
        $urlGenerator = \OC::$server->getURLGenerator();
        $this->db = $db;


        $loggingService = new LoggingService('ldapimporter', $config, $logger);
        $this->appService = new AppService('ldapimporter', $config, $loggingService, $userManager, $userSession, $urlGenerator);

        $userService = new UserService(
            'ldapimporter',
            $config,
            $userManager,
            $userSession,
            $groupManager,
            $this->appService,
            $loggingService
        );

        if ($this->appService->isNotNextcloud()) {

            $backend = new Backend(
                'ldapimporter',
                $config,
                $loggingService,
                $this->appService,
                $userManager
            );
        } else {

            $backend = new NextBackend(
                'ldapimporter',
                $config,
                $loggingService,
                $this->appService,
                $userManager,
                $userService
            );
        }

        $this->userService = $userService;
        $this->userManager = $userManager;
        $this->groupManager = $groupManager;
        $this->mailer = $mailer;
        $this->loggingService = $loggingService;
        $this->config = $config;
        $this->backend = $backend;
    }


    /**
     *
     */
    protected function configure()
    {
        $this
            ->setName('ldap:update-user')
            ->setDescription('Updates an existing user and, if not yet a CAS user, converts the record to CAS backend.')
            ->addArgument(
                'uid',
                InputArgument::REQUIRED,
                'User ID used to login (must only contain a-z, A-Z, 0-9, -, _ and @).'
            )
            ->addOption(
                'display-name',
                null,
                InputOption::VALUE_OPTIONAL,
                'User name used in the web UI (can contain any characters).'
            )
            ->addOption(
                'email',
                null,
                InputOption::VALUE_OPTIONAL,
                'Email address for the user.'
            )
            ->addOption(
                'group',
                'g',
                InputOption::VALUE_OPTIONAL | InputOption::VALUE_IS_ARRAY,
                'The groups the user should be added to (The group will be created if it does not exist).'
            )
            ->addOption(
                'quota',
                'o',
                InputOption::VALUE_OPTIONAL,
                'The quota the user should get, either as numeric value in bytes or as a human readable string (e.g. 1GB for 1 Gigabyte)'
            )
            ->addOption(
                'enabled',
                'e',
                InputOption::VALUE_OPTIONAL,
                'Set user enabled'
            )
            ->addOption(
                'convert-backend',
                'c',
                InputOption::VALUE_OPTIONAL,
                'Convert the backend to CAS'
            )
            ->addOption(
                'uai-courant',
                null,
                InputOption::VALUE_OPTIONAL,
                'Set user uai-courant'
            )
        ;
    }


    /**
     * @param InputInterface $input
     * @param OutputInterface $output
     * @return int|null
     * @throws \Exception
     */
    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $uid = $input->getArgument('uid');
        if (!$this->userManager->userExists($uid)) {
            $output->writeln('<error>The user "' . $uid . '" does not exist.</error>');
            return 1;
        }

        // Validate email before we create the user
        if ($input->getOption('email')) {
            // Validate first
            if (!$this->mailer->validateMailAddress($input->getOption('email'))) {
                // Invalid! Error
                $output->writeln('<error>Invalid email address supplied</error>');
                return 1;
            } else {
                $email = $input->getOption('email');
            }
        } else {
            $email = null;
        }

        # Register Backend
        $this->userService->registerBackend($this->backend);

        /**
         * @var IUser
         */
        $user = $this->userManager->get($uid);

        if ($user instanceof IUser) {

            $output->writeln('<info>The user "' . $user->getUID() . '" has been found</info>');
        } else {

            $output->writeln('<error>An error occurred while finding the user</error>');
            return 1;
        }

        # Set displayName
        if ($input->getOption('display-name')) {

            $user->setDisplayName($input->getOption('display-name'));
            $output->writeln('Display name set to "' . $user->getDisplayName() . '"');
        }

        # Set email if supplied & valid
        if ($email !== null) {

            $user->setEMailAddress($email);
            $output->writeln('Email address set to "' . $user->getEMailAddress() . '"');
        }

        # Set Groups
        $groups = (array)$input->getOption('group');

        if (count($groups) > 0) {

            $this->userService->updateGroups($user, $groups, $this->config->getAppValue('ldapimporter', 'cas_protected_groups'));
            $output->writeln('Groups have been updated.');
        }

        # Set Quota
        $quota = $input->getOption('quota');

        if (!empty($quota)) {

            if (is_numeric($quota)) {

                $newQuota = $quota;
            } elseif ($quota === 'default') {

                $newQuota = 'default';
            } elseif ($quota === 'none') {

                $newQuota = 'none';
            } else {

                $newQuota = \OCP\Util::computerFileSize($quota);
            }

            $user->setQuota($newQuota);
            $output->writeln('Quota set to "' . $user->getQuota() . '"');
        }

        # Set enabled
        $enabled = $input->getOption('enabled');

        if (is_numeric($enabled) || is_bool($enabled)) {

            $user->setEnabled(boolval($enabled));

            $enabledString = ($user->isEnabled()) ? 'enabled' : 'not enabled';
            $output->writeln('Enabled set to "' . $enabledString . '"');
        }

        # Convert backend
        $convertBackend = $input->getOption('convert-backend');

        if ($convertBackend) {

            # Set Backend
            if ($this->appService->isNotNextcloud()) {

                $query = \OC_DB::prepare('UPDATE `*PREFIX*accounts` SET `backend` = ? WHERE LOWER(`uid` = LOWER(?)');
                $result = $query->execute([get_class($this->backend), $uid]);

                $output->writeln('New user added to CAS backend.');

            } else {

                $output->writeln('This is a Nextcloud instance, no backend update needed.');

            }
        }
    }
}