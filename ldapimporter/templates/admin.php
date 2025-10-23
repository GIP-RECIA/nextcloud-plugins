<?php

use OCP\App\IAppManager;

script('ldapimporter', 'settings');
style('ldapimporter', 'settings');
?>

<form id="ldapimporter" method="post">
    <input type="hidden" autocomplete="false" />

    <div class="section">
        <h2><?php p($l->t('ActiveDirectory (LDAP)')); ?></h2>

        <div class="labeled-input">
            <label for="cas_import_ad_host">
                <?php p($l->t('LDAP Host')); ?>
            </label>
            <div style="display: inline-flex;align-items: center;gap: 4px;">
                <select id="cas_import_ad_protocol" name="cas_import_ad_protocol">
                    <?php $importAdProtocol = $_['cas_import_ad_protocol']; ?>
                    <option value="ldaps://" <?php echo $importAdProtocol === 'ldaps://' ? 'selected' : ''; ?>>ldaps://</option>
                    <option value="ldap://" <?php echo $importAdProtocol === 'ldap://' ? 'selected' : ''; ?>>ldap://</option>
                </select>
                <input
                    id="cas_import_ad_host"
                    name="cas_import_ad_host"
                    value="<?php p($_['cas_import_ad_host']); ?>"
                    placeholder="ldap.mydomain.com"
                    style="width: 31em;"/>
                :
                <input
                    id="cas_import_ad_port"
                    name="cas_import_ad_port"
                    value="<?php p($_['cas_import_ad_port']); ?>"
                    placeholder="636"
                    style="width: 6em;"/>
            </div>
        </div>
        <div class="labeled-input">
            <label for="cas_import_ad_user">
                <?php p($l->t('LDAP User')); ?>
            </label>
            <input
                id="cas_import_ad_user"
                name="cas_import_ad_user"
                value="<?php p($_['cas_import_ad_user']); ?>"
                placeholder="admin"/>
        </div>
        <div class="labeled-input">
            <label for="cas_import_ad_password">
                <?php p($l->t('LDAP User Password')); ?>
            </label>
            <input
                id="cas_import_ad_password"
                name="cas_import_ad_password"
                type="password"
                autocomplete="off"/>
        </div>
        <div class="labeled-input">
            <label for="cas_import_ad_base_dn">
                <?php p($l->t('LDAP Base DN')); ?>
            </label>
            <input
                id="cas_import_ad_base_dn"
                name="cas_import_ad_base_dn"
                value="<?php p($_['cas_import_ad_base_dn']); ?>"
                placeholder="OU=People,DC=mydomain,DC=com"/>
        </div>
        <div class="labeled-input">
            <label for="cas_import_ad_sync_filter">
                <?php p($l->t('LDAP Sync Filter')); ?>
            </label>
            <input
                id="cas_import_ad_sync_filter"
                name="cas_import_ad_sync_filter"
                value="<?php print_unescaped($_['cas_import_ad_sync_filter']); ?>"
                placeholder="(&(objectCategory=user)(objectClass=user)(memberof:1.2.840.113556.1.4.1941:=CN=owncloudusers,CN=Users,DC=mydomain,DC=com))"/>
        </div>
        <div class="labeled-input" style="display: flex;align-items: center;">
            <label for="cas_import_ad_sync_pagesize_value">
                <?php p($l->t('LDAP Sync Pagesize (1–1500)')); ?>
            </label>
            <div style="display: inline-flex;align-items: center;">
                <input
                    id="cas_import_ad_sync_pagesize"
                    name="cas_import_ad_sync_pagesize"
                    type="range"
                    min="1" max="1500" step="1"
                    value="<?php if(isset($_['cas_import_ad_sync_pagesize'])) { p($_['cas_import_ad_sync_pagesize']); } else { print_unescaped('1500'); } ?>"
                    onchange="updateRangeInput(this.value, 'cas_import_ad_sync_pagesize_value');"/>
                <input
                    id="cas_import_ad_sync_pagesize_value"
                    type="number"
                    size="4"
                    maxlength="4"
                    min="1"
                    max="1500"
                    value="<?php if(isset($_['cas_import_ad_sync_pagesize'])) { p($_['cas_import_ad_sync_pagesize']); } else { print_unescaped('1500'); } ?>"
                    style="width: 6em;"/>
            </div>
        </div>

        <div class="footer-actions">
            <input type="submit" value="<?php p($l->t('Save')); ?>"/>
        </div>
    </div>

    <div class="section">
        <h2><?php p($l->t('CLI Attribute Mapping')); ?></h2>

        <div class="labeled-input">
            <label for="cas_import_map_uid">
                <?php p($l->t('UID/Username')); ?>
            </label>
            <input
                id="cas_import_map_uid"
                name="cas_import_map_uid"
                value="<?php p($_['cas_import_map_uid']); ?>"
                placeholder="sn"/>
        </div>
        <div class="labeled-input">
            <label for="cas_import_map_displayname">
                <?php p($l->t('Display Name')); ?>
            </label>
            <input
                id="cas_import_map_displayname"
                name="cas_import_map_displayname"
                value="<?php p($_['cas_import_map_displayname']); ?>"
                placeholder="givenname"/>
        </div>
        <div class="labeled-input">
            <label for="cas_import_map_email">
                <?php p($l->t('Email')); ?>
            </label>
            <input
                id="cas_import_map_email"
                name="cas_import_map_email"
                value="<?php p($_['cas_import_map_email']); ?>"
                placeholder="email"/>
        </div>
        <div class="labeled-input">
            <label for="cas_import_map_groups_description">
                <?php p($l->t('Group Name Field')); ?>
            </label>
            <input
                id="cas_import_map_groups_description"
                name="cas_import_map_groups_description"
                value="<?php p($_['cas_import_map_groups_description']); ?>"
                placeholder="description"/>
        </div>
        <div class="labeled-input">
            <label for="cas_import_map_quota">
                <?php p($l->t('Quota')); ?>
            </label>
            <input
                id="cas_import_map_quota"
                name="cas_import_map_quota"
                value="<?php p($_['cas_import_map_quota']); ?>"
                placeholder="quota"/>
        </div>
        <div class="labeled-input">
            <label for="cas_import_map_enabled">
                <?php p($l->t('Enable')); ?>
            </label>
            <input
                id="cas_import_map_enabled"
                name="cas_import_map_enabled"
                value="<?php p($_['cas_import_map_enabled']); ?>"
                placeholder="useraccountcontrol"/>
        </div>
        <div class="labeled-input">
            <label for="cas_import_map_enabled_and_bitwise">
                <?php p($l->t('Calculate Enable Attribute Bitwise AND with')); ?>
            </label>
            <input
                id="cas_import_map_enabled_and_bitwise"
                name="cas_import_map_enabled_and_bitwise"
                value="<?php p($_['cas_import_map_enabled_and_bitwise']); ?>"
                placeholder="2"/>
        </div>
        <div class="labeled-checkbox">
            <input
                id="cas_import_merge"
                name="cas_import_merge"
                type="checkbox"
                <?php print_unescaped((($_['cas_import_merge'] === 'true' || $_['cas_import_merge'] === 'on' || $_['cas_import_merge'] === '1') ? 'checked="checked"' : '')); ?>>
            <label class='checkbox' for="cas_import_merge">
                <?php p($l->t('Merge Accounts')); ?>
            </label>
        </div>
        <div class="labeled-checkbox">
            <input
                id="cas_import_merge_enabled"
                name="cas_import_merge_enabled"
                type="checkbox"
                <?php print_unescaped((($_['cas_import_merge_enabled'] === 'true' || $_['cas_import_merge_enabled'] === 'on' || $_['cas_import_merge_enabled'] === '1') ? 'checked="checked"' : '')); ?>>
            <label class='checkbox' for="cas_import_merge_enabled">
                <?php p($l->t('Prefer Enabled over Disabled Accounts on Merge')); ?>
            </label>
        </div>
        <div class="labeled-input">
            <label for="cas_import_map_dn">
                <?php p($l->t('Merge Two Active Accounts by')); ?>
            </label>
            <input
                id="cas_import_map_dn"
                name="cas_import_map_dn"
                value="<?php p($_['cas_import_map_dn']); ?>"
                placeholder="dn"/>
        </div>
        <div class="labeled-input">
            <label for="cas_import_map_dn_filter">
                <?php p($l->t('Merge Two Active Accounts by: Filterstring')); ?>
            </label>
            <input
                id="cas_import_map_dn_filter"
                name="cas_import_map_dn_filter"
                value="<?php p($_['cas_import_map_dn_filter']); ?>"
                placeholder="cn=p"/>
        </div>

        <div class="footer-actions">
            <input type="submit" value="<?php p($l->t('Save')); ?>"/>
        </div>
    </div>

    <div class="section">
        <h2>Groupe fonctionnel</h2>
        <div class="labeled-input">
            <label for="cas_import_map_groups"">
                <?php p($l->t('Nom de l\'attribut LDAP des utilisteurs')); ?>
            </label>
            <input
                id="cas_import_map_groups"
                name="cas_import_map_groups"
                value="<?php p($_['cas_import_map_groups']); ?>"
                placeholder="Nom de l\'attribut LDAP des utilisteurs"/>
        </div>
        
        <div style="margin-top: 2em;">
            <input
                id="cas_import_map_regex_name_uai"
                name="cas_import_map_regex_name_uai"
                value="<?php p($_['cas_import_map_regex_name_uai']); ?>"
                data-value="<?php p($_['cas_import_map_regex_name_uai']); ?>"
                style="display: none;width: 100%;"/>
            <div style="display: grid;grid-template-columns: 3fr 1fr 1fr;column-gap: 4px;" class="cw-100">
                <div>
                    <label for="cas_import_regex_name_uai">
                        <?php p($l->t('Regex de nommage d\'établissement et du UAI')); ?>
                    </label>
                    <p style="color: gray;">
                        Les groupements de la regex pour le nom et l'UAI de l'établissement sont défini ci-contre
                    </p>
                </div>
                <label style="width: 100%" for="cas_import_regex_name_group">
                    <?php p($l->t('Numéro du groupement dans la regex correspondant au nom de l\'établissement')); ?>
                </label>
                <label style="width: 100%" for="cas_import_regex_uai_group">
                    <?php p($l->t('Numéro du groupement dans la regex correspondant à l\'UAI de l\'établissement')); ?>
                </label>
                <input
                    id="cas_import_regex_name_uai_first"
                    class="cas_import_regex_name_uai"
                    value=""/>
                <input
                    id="cas_import_regex_name_group_first"
                    class="cas_import_regex_name_group"
                    value=""/>
                <input
                    id="cas_import_regex_uai_group_first"
                    class="cas_import_regex_uai_group"
                    value=""/>
                <button id="addNameUaiGroup" type="button" style="width: 34px;">+</button>
            </div>

            <div class="footer-actions">
                <input type="submit" value="<?php p($l->t('Save')); ?>"/>
            </div>
        </div>

        <div style="margin-top: 2em;">
            <input
                id="cas_import_map_groups_fonctionel"
                name="cas_import_map_groups_fonctionel"
                value="<?php p($_['cas_import_map_groups_fonctionel']); ?>"
                data-value="<?php p($_['cas_import_map_groups_fonctionel']); ?>"
                style="display: none;width: 100%;"/>
            <div style="display: grid;grid-template-columns: 6fr 2fr 1fr 1fr;column-gap: 4px;" class="cw-100">
                <label><?php p($l->t('Regex de filtre')); ?></label>
                <label><?php p($l->t('Nommage')); ?></label>
                <label><?php p($l->t('Numéro du groupement de la regex pour l\'UAI ou le nom')); ?></label>
                <label><?php p($l->t('Quota (en GB)')); ?></label>
                <input
                    id="cas_import_map_groups_filter_first"
                    class="cas_import_map_groups_filter"
                    value=""/>
                <input
                    id="cas_import_map_groups_naming_first"
                    class="cas_import_map_groups_naming"
                    value=""/>
                <input
                    id="cas_import_map_groups_uai_number_first"
                    class="cas_import_map_groups_uai_number"
                    value=""/>
                <input
                    id="cas_import_map_groups_quota_first"
                    class="cas_import_map_groups_quota"
                    value=""/>
                <button id="addFilterGroup" type="button" style="width: 34px;">+</button>
            </div>
        </div>

        <div class="footer-actions">
            <input type="submit" value="<?php p($l->t('Save')); ?>"/>
        </div>
    </div>

    <div class="section">
        <h2>Groupe pédagogiques</h2>
        <p>
            Informations sur la syntaxe de nommage : Le champs de nommage utilise la syntaxe des littéraux de gabarits ${maVariable}, de plus vous pouvez utiliser la variable ${nomEtablissement} pour insérer le nom de l'établissement dans le nommage
        </p>

        <div>
            <input
                id="cas_import_map_groups_pedagogic"
                name="cas_import_map_groups_pedagogic"
                value="<?php p($_['cas_import_map_groups_pedagogic']); ?>"
                data-value="<?php p($_['cas_import_map_groups_pedagogic']); ?>"
                style="display: none;width: 100%;"/>
            <div style="display: grid;grid-template-columns: 1fr 1fr 3fr;column-gap: 4px;" class="cw-100">
                <label><?php p($l->t('Nom de l\'attribut LDAP des utilisteurs')); ?></label>
                <label><?php p($l->t('Regex de filtre')); ?></label>
                <label><?php p($l->t('Nommage')); ?></label>
                <input
                    id="cas_import_map_groups_pedagogic_first"
                    class="cas_import_map_groups_pedagogic"
                    value=""/>
                <input
                    id="cas_import_map_groups_pedagogic_filter_first"
                    class="cas_import_map_groups_pedagogic_filter"
                    value=""/>
                <input
                    id="cas_import_map_groups_pedagogic_naming_first"
                    class="cas_import_map_groups_pedagogic_naming"
                    value=""/>
                <button id="addPedagogicGroup" type="button" style="width: 34px;">+</button>
            </div>
        </div>

        <div class="footer-actions">
            <input type="submit" value="<?php p($l->t('Save')); ?>"/>
        </div>
    </div>
    <input type="hidden" value="<?php p($_['requesttoken']); ?>" name="requesttoken"/>
</form>
