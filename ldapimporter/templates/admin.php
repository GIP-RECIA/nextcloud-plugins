<?php

script('ldapimporter', 'settings');
style('ldapimporter', 'settings');
?>

<form id="ldapimporter" class='section' method="post">

    <input type="hidden" autocomplete="false" />

    <h2><?php p($l->t('Import Users')); ?>
        &nbsp;<?php p(\OCP\App::getAppInfo('ldap_mporter')["version"]); ?></h2>

    <div id="casSettings" class="personalblock">
        <ul>
            <li><a href="#casSettings-6"><?php p($l->t('Config LDAP')); ?></a></li>
            <li><a href="#casSettings-8"><?php p($l->t('Filtre & nommage de groupe')); ?></a></li>
        </ul>
        <!-- CAS Server Settings -->
        <!-- Import-CLI Settings -->
        <fieldset id="casSettings-6">

            <h3><?php p($l->t('ActiveDirectory (LDAP)')); ?>:</h3>

            <p><label for="cas_import_ad_host"><?php p($l->t('LDAP Host')); ?></label>
                <select id="cas_import_ad_protocol" name="cas_import_ad_protocol">
                    <?php $importAdProtocol = $_['cas_import_ad_protocol']; ?>
                    <option value="ldaps://" <?php echo $importAdProtocol === 'ldaps://' ? 'selected' : ''; ?>>ldaps://</option>
                    <option value="ldap://" <?php echo $importAdProtocol === 'ldap://' ? 'selected' : ''; ?>>ldap://</option>

                </select>
                <input
                        id="cas_import_ad_host"
                        name="cas_import_ad_host"
                        value="<?php p($_['cas_import_ad_host']); ?>" placeholder="ldap.mydomain.com"/>
                :
                <input
                        id="cas_import_ad_port"
                        name="cas_import_ad_port"
                        value="<?php p($_['cas_import_ad_port']); ?>" placeholder="636"/>
            </p>
            <p><label for="cas_import_ad_user"><?php p($l->t('LDAP User and Domain')); ?></label>
                <input
                        id="cas_import_ad_user"
                        name="cas_import_ad_user"
                        value="<?php p($_['cas_import_ad_user']); ?>" placeholder="admin"/>
                @
                <input
                        id="cas_import_ad_domain"
                        name="cas_import_ad_domain"
                        value="<?php p($_['cas_import_ad_domain']); ?>" placeholder="ldap.mydomain.com"/>
            </p>
            <p><label for="cas_import_ad_password"><?php p($l->t('LDAP User Password')); ?></label>
                <input
                        type="password"
                        id="cas_import_ad_password"
                        name="cas_import_ad_password"/>
            </p>
            <p><label for="cas_import_ad_base_dn"><?php p($l->t('LDAP Base DN')); ?></label>
                <input
                        id="cas_import_ad_base_dn"
                        name="cas_import_ad_base_dn"
                        value="<?php p($_['cas_import_ad_base_dn']); ?>" placeholder="OU=People,DC=mydomain,DC=com"/>
            </p>
            <p><label for="cas_import_ad_sync_filter"><?php p($l->t('LDAP Sync Filter')); ?></label>
                <input
                        id="cas_import_ad_sync_filter"
                        name="cas_import_ad_sync_filter"
                        value="<?php print_unescaped($_['cas_import_ad_sync_filter']); ?>" placeholder="(&(objectCategory=user)(objectClass=user)(memberof:1.2.840.113556.1.4.1941:=CN=owncloudusers,CN=Users,DC=mydomain,DC=com))"/>
            </p>
            <p><label for="cas_import_ad_sync_pagesize_value"><?php p($l->t('LDAP Sync Pagesize (1–1500)')); ?></label>
                <input
                        type="range"
                        min="1" max="1500" step="1"
                        id="cas_import_ad_sync_pagesize"
                        name="cas_import_ad_sync_pagesize"
                        value="<?php if(isset($_['cas_import_ad_sync_pagesize'])) { p($_['cas_import_ad_sync_pagesize']); } else { print_unescaped('1500'); } ?>"
                onchange="updateRangeInput(this.value, 'cas_import_ad_sync_pagesize_value');"/>
                <input type="number" id="cas_import_ad_sync_pagesize_value" size="4" maxlength="4" min="1" max="1500" value="<?php if(isset($_['cas_import_ad_sync_pagesize'])) { p($_['cas_import_ad_sync_pagesize']); } else { print_unescaped('1500'); } ?>">
            </p>

            <h3><?php p($l->t('CLI Attribute Mapping')); ?>:</h3>

            <p><label for="cas_import_map_uid"><?php p($l->t('UID/Username')); ?></label>
                <input
                        id="cas_import_map_uid"
                        name="cas_import_map_uid"
                        value="<?php p($_['cas_import_map_uid']); ?>" placeholder="sn"/>
            </p>
            <p><label for="cas_import_map_displayname"><?php p($l->t('Display Name')); ?></label>
                <input
                        id="cas_import_map_displayname"
                        name="cas_import_map_displayname"
                        value="<?php p($_['cas_import_map_displayname']); ?>" placeholder="givenname"/>
            </p>
            <p><label for="cas_import_map_email"><?php p($l->t('Email')); ?></label>
                <input
                        id="cas_import_map_email"
                        name="cas_import_map_email"
                        value="<?php p($_['cas_import_map_email']); ?>" placeholder="email"/>
            </p>

            <p><label for="cas_import_map_groups_description"><?php p($l->t('Group Name Field')); ?></label>
                <input
                        id="cas_import_map_groups_description"
                        name="cas_import_map_groups_description"
                        value="<?php p($_['cas_import_map_groups_description']); ?>" placeholder="description"/>
            </p>

            <p><label for="cas_import_map_quota"><?php p($l->t('Quota')); ?></label>
                <input
                        id="cas_import_map_quota"
                        name="cas_import_map_quota"
                        value="<?php p($_['cas_import_map_quota']); ?>" placeholder="quota"/>
            </p>
            <p><label for="cas_import_map_enabled"><?php p($l->t('Enable')); ?></label>
                <input
                        id="cas_import_map_enabled"
                        name="cas_import_map_enabled"
                        value="<?php p($_['cas_import_map_enabled']); ?>" placeholder="useraccountcontrol"/>
            </p>
            <p><label for="cas_import_map_enabled_and_bitwise"><?php p($l->t('Calculate Enable Attribute Bitwise AND with')); ?></label>
                <input
                        id="cas_import_map_enabled_and_bitwise"
                        name="cas_import_map_enabled_and_bitwise"
                        value="<?php p($_['cas_import_map_enabled_and_bitwise']); ?>" placeholder="2"/>
            </p>

            <p>
                <input type="checkbox" id="cas_import_merge"
                      name="cas_import_merge" <?php print_unescaped((($_['cas_import_merge'] === 'true' || $_['cas_import_merge'] === 'on' || $_['cas_import_merge'] === '1') ? 'checked="checked"' : '')); ?>>
                <label class='checkbox'
                       for="cas_import_merge"><?php p($l->t('Merge Accounts')); ?></label>
            </p>
            <p>
                <input type="checkbox" id="cas_import_merge_enabled"
                      name="cas_import_merge_enabled" <?php print_unescaped((($_['cas_import_merge_enabled'] === 'true' || $_['cas_import_merge_enabled'] === 'on' || $_['cas_import_merge_enabled'] === '1') ? 'checked="checked"' : '')); ?>>
                <label class='checkbox'
                       for="cas_import_merge_enabled"><?php p($l->t('Prefer Enabled over Disabled Accounts on Merge')); ?></label>
            </p>
            <p><label for="cas_import_map_dn"><?php p($l->t('Merge Two Active Accounts by')); ?></label>
                <input
                        id="cas_import_map_dn"
                        name="cas_import_map_dn"
                        value="<?php p($_['cas_import_map_dn']); ?>" placeholder="dn"/>
            </p>
            <p><label for="cas_import_map_dn_filter"><?php p($l->t('Merge Two Active Accounts by: Filterstring')); ?></label>
                <input
                        id="cas_import_map_dn_filter"
                        name="cas_import_map_dn_filter"
                        value="<?php p($_['cas_import_map_dn_filter']); ?>" placeholder="cn=p"/>
            </p>
        </fieldset>
        <!-- Recia groups Settings -->
        <fieldset id="casSettings-8">
            <h3>Groupe fonctionnel</h3>
            <br>
            <div style="display: flex;">
                <p>
                    <label for="cas_import_map_groups"><?php p($l->t('Nom de l\'attribut LDAP des utilisteurs')); ?></label>
                    <input
                            style="width: 50%"
                            id="cas_import_map_groups"
                            name="cas_import_map_groups"
                            value="<?php p($_['cas_import_map_groups']); ?>" placeholder="Nom de l\'attribut LDAP des utilisteurs"/>
                </p>
            </div>
            <br>
            <div style="display: flex;justify-content: space-between">
                <div style="width: 40%">
                    <label style="width: 100%" for="cas_import_regex_name_uai"><?php p($l->t('Regex de nommage d\'établissement et du UAI')); ?></label>
                    <p style="color: gray">Les groupements de la regex pour le nom et l'UAI de l'établissement sont défini ci-contre</p>
                    <input
                            style="width: 100%"
                            id="cas_import_regex_name_uai"
                            name="cas_import_regex_name_uai"
                            value="<?php p($_['cas_import_regex_name_uai']); ?>" placeholder="Regex de nommage d'établissement et du UAI"/>
                </div>
                <div style="width: 25%">
                    <label style="width: 100%" for="cas_import_regex_name_group"><?php p($l->t('Numéro du groupement dans la regex correspondant au nom de l\'établissement')); ?></label>
                    <p style="color: gray"></p>
                    <input
                            style="width: 100%"
                            id="cas_import_regex_name_group"
                            name="cas_import_regex_name_group"
                            value="<?php p($_['cas_import_regex_name_group']); ?>" placeholder="Numéro du groupement dans la regex correspondant au nom de l'établissement"/>
                </div>
                <div style="width: 25%">
                    <label style="width: 100%" for="cas_import_regex_uai_group"><?php p($l->t('Numéro du groupement dans la regex correspondant à l\'UAI de l\'établissement')); ?></label>
                    <p style="color: gray"></p>
                    <input
                            style="width: 100%"
                            id="cas_import_regex_uai_group"
                            name="cas_import_regex_uai_group"
                            value="<?php p($_['cas_import_regex_uai_group']); ?>" placeholder="Numéro du groupement dans la regex correspondant à l'UAI de l'établissement"/>
                </div>
            </div>
            <br>
            <div>
                <div>
                    <p style="display: none;"><label for="cas_import_map_groups_fonctionel"><?php p($l->t('Regex de filtre')); ?></label>
                        <input
                                id="cas_import_map_groups_fonctionel"
                                name="cas_import_map_groups_fonctionel"
                                value="<?php p($_['cas_import_map_groups_fonctionel']); ?>"
                                data-value="<?php p($_['cas_import_map_groups_fonctionel']); ?>"/>
                    </p>
                </div>
                <div style="display: flex">
                    <p>
                        <label><?php p($l->t('Regex de filtre')); ?></label>
                        <input
                                style="width: 90%"
                                id="cas_import_map_groups_filter_first"
                                class="cas_import_map_groups_filter"
                                value=""
                                placeholder="Regex de filtre"/>
                    </p>
                    <p>
                        <label><?php p($l->t('Nommage')); ?></label>
                        <input
                                style="width: 90%"
                                id="cas_import_map_groups_naming_first"
                                class="cas_import_map_groups_naming"
                                value="" placeholder="Nommage"/>
                    </p>
                    <p>
                        <label><?php p($l->t('Quota (en GB')); ?></label>
                        <input
                            style="width: 90%"
                            id="cas_import_map_groups_quota_first"
                            class="cas_import_map_groups_quota"
                            value="" placeholder="Quota"/>
                    </p>
                </div>
                <button id="addFilterGroup" type="button" style="width: 34px;">+</button>
            </div>
            <br>
            <h3>Groupe pédagogiques</h3>
            <p>Informations sur la syntaxe de nommage : Le champs de nommage utilise la syntaxe des littéraux de gabarits ${maVariable} </p>
            <br>
            <div>
                <div>
                    <p style="display: none;"><label for="cas_import_map_groups_pedagogic"><?php p($l->t('Groupes pédagogique')); ?></label>
                        <input
                                style="width: 90%"
                                id="cas_import_map_groups_pedagogic"
                                name="cas_import_map_groups_pedagogic"
                                value="<?php p($_['cas_import_map_groups_pedagogic']); ?>"
                                data-value="<?php p($_['cas_import_map_groups_pedagogic']); ?>"/>
                    </p>
                </div>
                <div style="display: flex;">
                    <p style="width: 25%"><label><?php p($l->t('Nom de l\'attribut LDAP des utilisteurs')); ?></label>
                        <input
                                style="width: 90%"
                                id="cas_import_map_groups_pedagogic_first"
                                class="cas_import_map_groups_pedagogic"
                                value=""
                                placeholder="Nom de l\'attribut LDAP des utilisteurs"/>
                    </p>
                    <p style="width: 50%"><label><?php p($l->t('Regex de filtre')); ?></label>
                        <input
                                style="width: 90%"
                                id="cas_import_map_groups_pedagogic_filter_first"
                                class="cas_import_map_groups_pedagogic_filter"
                                value=""
                                placeholder="Regex de filtre"/>
                    </p>
                    <p style="width: 25%"><label><?php p($l->t('Nommage')); ?></label>
                        <input
                                style="width: 90%"
                                id="cas_import_map_groups_pedagogic_naming_first"
                                class="cas_import_map_groups_pedagogic_naming"
                                value=""
                                placeholder="Nommage"/>
                    </p>

                </div>
                <button id="addPedagogicGroup" type="button">+</button>
            </div>

        </fieldset>
        <input type="hidden" value="<?php p($_['requesttoken']); ?>" name="requesttoken"/>
        <input id="importSettingsSubmit" type="submit" value="<?php p($l->t('Save')); ?>"/>
    </div>
</form>
