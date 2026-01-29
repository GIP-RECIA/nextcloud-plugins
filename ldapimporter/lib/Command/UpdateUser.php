<?php

namespace OCA\LdapImporter\Command;

use OC\Core\Command\Base;
use OCA\LdapImporter\Service\UserService;
use OCA\LdapImporter\User\Backend;
use OCP\IGroupManager;
use OCP\IUser;
use OCP\IUserManager;
use OCP\Mail\IEmailValidator;
use OCP\Security\ISecureRandom;
use OCP\Util;
use Psr\Log\LoggerInterface;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Logger\ConsoleLogger;
use Symfony\Component\Console\Output\OutputInterface;

class UpdateUser extends Base
{
    private UserService $userService;
    private Backend $backend;

    public function __construct(
        private IGroupManager $groupManager,
        private IUserManager $userManager,
        private IEmailValidator $emailValidator,
        private ISecureRandom $secureRandom,
        private LoggerInterface $loggerInterface
    ) {
        parent::__construct();

        $this->userService = new UserService(
            $groupManager,
            $userManager,
            $secureRandom,
            $loggerInterface
        );
        $this->backend = new Backend();
    }

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
                'uai-courant',
                null,
                InputOption::VALUE_OPTIONAL,
                'Set user uai-courant'
            )
            ->addOption(
                'convert-backend',
                'c',
                InputOption::VALUE_OPTIONAL,
                'Convert the backend to CAS'
            );
        parent::configure();
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $logger = new ConsoleLogger($output);
        $uid = $input->getArgument('uid');
        if (!$this->userManager->userExists($uid)) {
            //$output->writeln('<error>The user "' . $uid . '" does not exist.</error>');
            $logger->error('The user "' . $uid . '" does not exist');
            return 1;
        }

        // Validate email before we create the user
        $email = $input->getOption('email');
        if ($email !== null) {
            // Validate first
            if (!$this->emailValidator->isValid($email)) {
                // Invalid! Error
                //$output->writeln('<error>Invalid email address supplied</error>');
                $logger->error("Invalide email ($email) for $uid");
                $email = null;
            }
        }

        # Register Backend
        $this->userService->registerBackend($this->backend);

        $user = $this->userManager->get($uid);

        if ($user instanceof IUser) {
            $output->writeln('<info>The user "' . $user->getUID() . '" has been found</info>');
        } else {
            //$output->writeln('<error>An error occurred while finding the user</error>');
            $logger->error("An error occurred while finding the user $uid");
            return 1;
        }

        # Set displayName
        if ($input->getOption('display-name')) {
            $user->setDisplayName($input->getOption('display-name'));
            $output->writeln('Display name set to "' . $user->getDisplayName() . '"');
        } else {
            $output->writeln('no Display-name');
        }

        # Set email if supplied & valid
        if ($email !== null) {
            $user->setSystemEMailAddress($email);
            $output->writeln('Email address set to "' . $user->getEMailAddress() . '"');
        } else {
            $output->writeln('no Email ');
        }

        # Set Groups
        $groups = (array)$input->getOption('group');
        if (count($groups) > 0) {
            $this->userService->updateGroups($user, $groups);
            $output->writeln('Groups have been updated.');
        } else {
            $output->writeln('no groups ');
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
                $newQuota = Util::computerFileSize($quota);
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

        return 0;
    }
}
