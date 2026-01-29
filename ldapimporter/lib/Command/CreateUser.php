<?php

declare(strict_types=1);

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

class CreateUser extends Base
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
            ->setName('ldap:create-user')
            ->setDescription('Adds a ldapimporter user to the database.')
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
                'The quota the user should get either as numeric value in bytes or as a human readable string (e.g. 1GB for 1 Gigabyte)'
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
            );
        parent::configure();
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        //$output->writeln("begin create user " . $user->getUID() ); /* pl no commit */
        $logger = new ConsoleLogger($output);
        $uid = $input->getArgument('uid');
        if ($this->userManager->userExists($uid)) {
            //$output->writeln('<error>The user "' . $uid . '" already exists.</error>');
            $logger->error('The user "' . $uid . '" already exists');
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

        $user = $this->userService->create($uid, $this->backend);

        if ($user instanceof IUser) {
            $output->writeln('<info>The user "' . $user->getUID() . '" was created successfully</info>');
        } else {
            //$output->writeln('<error>An error occurred while creating the user</error>');
            $logger->error("An error occurred while creating the user $uid");

            return 1;
        }

        # Set displayName
        if ($input->getOption('display-name')) {
            $user->setDisplayName($input->getOption('display-name'));
            $output->writeln('Display name set to "' . $user->getDisplayName() . '"');
        } else {
            $output->writeln('no display-name');
        }

        # Set email if supplied & valid
        if ($email !== null) {
            $user->setSystemEMailAddress($email);
            $output->writeln('Email address set to "' . $user->getEMailAddress() . '"');
        } else {
            $output->writeln('no Email address');
        }

        # Set Groups
        $groups = (array)$input->getOption('group');
        if (count($groups) > 0) {
            $this->userService->updateGroups($user, $groups, '', true);
            $output->writeln('Groups have been set.');
        } else {
            $output->writeln('no Groups');
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
        } else {
            $output->writeln('no Quota');
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
