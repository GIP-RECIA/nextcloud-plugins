<?php

declare(strict_types=1);

use OCA\LdapImporter\AppInfo\Application;
use OCP\Util;

Util::addScript(Application::APP_ID, 'settings');
style(Application::APP_ID, 'settings');
?>

<form id="ldapimporter" method="post">
    <input type="hidden" autocomplete="false" />

    <div class="section">
        <h2>LDAP</h2>

        <div class="labeled-input">
            <label for="cas_import_ad_host">
                Hôte
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
                    style="width: 31em;" />
                :
                <input
                    id="cas_import_ad_port"
                    name="cas_import_ad_port"
                    value="<?php p($_['cas_import_ad_port']); ?>"
                    placeholder="636"
                    style="width: 6em;" />
            </div>
        </div>
        <div class="labeled-input">
            <label for="cas_import_ad_user">
                Utilisateur
            </label>
            <input
                id="cas_import_ad_user"
                name="cas_import_ad_user"
                value="<?php p($_['cas_import_ad_user']); ?>"
                placeholder="admin" />
        </div>
        <div class="labeled-input">
            <label for="cas_import_ad_password">
                Mot de passe
            </label>
            <input
                id="cas_import_ad_password"
                name="cas_import_ad_password"
                type="password"
                autocomplete="off" />
        </div>
        <div class="labeled-input">
            <label for="cas_import_ad_base_dn">
                Base DN
            </label>
            <input
                id="cas_import_ad_base_dn"
                name="cas_import_ad_base_dn"
                value="<?php p($_['cas_import_ad_base_dn']); ?>"
                placeholder="OU=People,DC=mydomain,DC=com" />
        </div>
        <div class="labeled-input">
            <label for="cas_import_ad_sync_filter">
                Filtre de synchronisation
            </label>
            <input
                id="cas_import_ad_sync_filter"
                name="cas_import_ad_sync_filter"
                value="<?php print_unescaped($_['cas_import_ad_sync_filter']); ?>"
                placeholder="(&(objectCategory=user)(objectClass=user)(memberof:1.2.840.113556.1.4.1941:=CN=owncloudusers,CN=Users,DC=mydomain,DC=com))" />
        </div>
        <div class="labeled-input" style="display: flex;align-items: center;">
            <label for="cas_import_ad_sync_pagesize_value">
                Taille de la page (1–1500)
            </label>
            <div style="display: inline-flex;align-items: center;">
                <input
                    id="cas_import_ad_sync_pagesize"
                    name="cas_import_ad_sync_pagesize"
                    type="range"
                    min="1" max="1500" step="1"
                    value="<?php if (isset($_['cas_import_ad_sync_pagesize'])) {
                                p($_['cas_import_ad_sync_pagesize']);
                            } else {
                                print_unescaped('1500');
                            } ?>"
                    onchange="updateRangeInput(this.value, 'cas_import_ad_sync_pagesize_value');" />
                <input
                    id="cas_import_ad_sync_pagesize_value"
                    type="number"
                    size="4"
                    maxlength="4"
                    min="1"
                    max="1500"
                    value="<?php if (isset($_['cas_import_ad_sync_pagesize'])) {
                                p($_['cas_import_ad_sync_pagesize']);
                            } else {
                                print_unescaped('1500');
                            } ?>"
                    style="width: 6em;" />
            </div>
        </div>

        <div class="footer-actions">
            <input type="submit" value="Enregistrer" />
        </div>
    </div>

    <div class="section">
        <h2> Mappage d'attributs CLI</h2>

        <div class="labeled-input">
            <label for="cas_import_map_uid">
                UID/Nom d'utilisateur
            </label>
            <input
                id="cas_import_map_uid"
                name="cas_import_map_uid"
                value="<?php p($_['cas_import_map_uid']); ?>"
                placeholder="sn" />
        </div>
        <div class="labeled-input">
            <label for="cas_import_map_displayname">
                Nom d'affichage
            </label>
            <input
                id="cas_import_map_displayname"
                name="cas_import_map_displayname"
                value="<?php p($_['cas_import_map_displayname']); ?>"
                placeholder="givenname" />
        </div>
        <div class="labeled-input">
            <label for="cas_import_map_email">
                Email
            </label>
            <input
                id="cas_import_map_email"
                name="cas_import_map_email"
                value="<?php p($_['cas_import_map_email']); ?>"
                placeholder="email" />
        </div>
        <div class="labeled-input">
            <label for="cas_import_map_groups_description">
                Nom du groupe
            </label>
            <input
                id="cas_import_map_groups_description"
                name="cas_import_map_groups_description"
                value="<?php p($_['cas_import_map_groups_description']); ?>"
                placeholder="description" />
        </div>
        <div class="labeled-input">
            <label for="cas_import_map_quota">
                Quota
            </label>
            <input
                id="cas_import_map_quota"
                name="cas_import_map_quota"
                value="<?php p($_['cas_import_map_quota']); ?>"
                placeholder="quota" />
        </div>
        <div class="labeled-input">
            <label for="cas_import_map_enabled">
                Activé
            </label>
            <input
                id="cas_import_map_enabled"
                name="cas_import_map_enabled"
                value="<?php p($_['cas_import_map_enabled']); ?>"
                placeholder="useraccountcontrol" />
        </div>
        <div class="labeled-input">
            <label for="cas_import_map_enabled_and_bitwise">
                Calculer l'attribut d'activation AND bit à bit avec
            </label>
            <input
                id="cas_import_map_enabled_and_bitwise"
                name="cas_import_map_enabled_and_bitwise"
                value="<?php p($_['cas_import_map_enabled_and_bitwise']); ?>"
                placeholder="2" />
        </div>
        <div class="labeled-checkbox">
            <input
                id="cas_import_merge"
                name="cas_import_merge"
                type="checkbox"
                <?php print_unescaped((($_['cas_import_merge'] === 'true' || $_['cas_import_merge'] === 'on' || $_['cas_import_merge'] === '1') ? 'checked="checked"' : '')); ?>>
            <label class='checkbox' for="cas_import_merge">
                Fusionner les comptes
            </label>
        </div>
        <div class="labeled-checkbox">
            <input
                id="cas_import_merge_enabled"
                name="cas_import_merge_enabled"
                type="checkbox"
                <?php print_unescaped((($_['cas_import_merge_enabled'] === 'true' || $_['cas_import_merge_enabled'] === 'on' || $_['cas_import_merge_enabled'] === '1') ? 'checked="checked"' : '')); ?>>
            <label class='checkbox' for="cas_import_merge_enabled">
                Préférer les comptes activés aux comptes désactivés lors de la fusion
            </label>
        </div>
        <div class="labeled-input">
            <label for="cas_import_map_dn">
                Fusionner deux comptes actifs par
            </label>
            <input
                id="cas_import_map_dn"
                name="cas_import_map_dn"
                value="<?php p($_['cas_import_map_dn']); ?>"
                placeholder="dn" />
        </div>
        <div class="labeled-input">
            <label for="cas_import_map_dn_filter">
                Filtre de fusion des comptes actifs
            </label>
            <input
                id="cas_import_map_dn_filter"
                name="cas_import_map_dn_filter"
                value="<?php p($_['cas_import_map_dn_filter']); ?>"
                placeholder="cn=p" />
        </div>

        <div class="footer-actions">
            <input type="submit" value="Enregistrer" />
        </div>
    </div>

    <div class="section">
        <h2>Groupes fonctionnels</h2>
        <div class="labeled-input">
            <label for="cas_import_map_groups"">
                Nom de l'attribut LDAP
            </label>
            <input
                id=" cas_import_map_groups"
                name="cas_import_map_groups"
                value="<?php p($_['cas_import_map_groups']); ?>"
                placeholder="Nom de l'attribut LDAP des utilisteurs" />
        </div>

        <div style="margin-top: 2em;">
            <input
                id="cas_import_map_regex_name_uai"
                name="cas_import_map_regex_name_uai"
                value="<?php p($_['cas_import_map_regex_name_uai']); ?>"
                data-value="<?php p($_['cas_import_map_regex_name_uai']); ?>"
                style="display: none;width: 100%;" />
            <div style="display: grid;grid-template-columns: 3fr 1fr 1fr;column-gap: 4px;" class="cw-100">
                <div>
                    <label for="cas_import_regex_name_uai">
                        Regex de nommage d\'établissement et du UAI
                    </label>
                    <p style="color: gray;">
                        Les groupements de la regex pour le nom et l'UAI de l'établissement sont défini ci-contre
                    </p>
                </div>
                <label style="width: 100%" for="cas_import_regex_name_group">
                    Numéro du groupement dans la regex correspondant au nom de l'établissement
                </label>
                <label style="width: 100%" for="cas_import_regex_uai_group">
                    Numéro du groupement dans la regex correspondant à l'UAI de l'établissement
                </label>
                <input
                    id="cas_import_regex_name_uai_first"
                    class="cas_import_regex_name_uai"
                    value="" />
                <input
                    id="cas_import_regex_name_group_first"
                    class="cas_import_regex_name_group"
                    value="" />
                <input
                    id="cas_import_regex_uai_group_first"
                    class="cas_import_regex_uai_group"
                    value="" />
                <button id="addNameUaiGroup" type="button" style="width: 34px;">+</button>
            </div>

            <div class="footer-actions">
                <input type="submit" value="Enregistrer" />
            </div>
        </div>

        <div style="margin-top: 2em;">
            <input
                id="cas_import_map_groups_fonctionel"
                name="cas_import_map_groups_fonctionel"
                value="<?php p($_['cas_import_map_groups_fonctionel']); ?>"
                data-value="<?php p($_['cas_import_map_groups_fonctionel']); ?>"
                style="display: none;width: 100%;" />
            <div style="display: grid;grid-template-columns: 6fr 2fr 1fr 1fr;column-gap: 4px;" class="cw-100">
                <label>Regex de filtre</label>
                <label>Nommage</label>
                <label>Numéro du groupement de la regex pour l'UAI ou le nom</label>
                <label>Quota (en GB)</label>
                <input
                    id="cas_import_map_groups_filter_first"
                    class="cas_import_map_groups_filter"
                    value="" />
                <input
                    id="cas_import_map_groups_naming_first"
                    class="cas_import_map_groups_naming"
                    value="" />
                <input
                    id="cas_import_map_groups_uai_number_first"
                    class="cas_import_map_groups_uai_number"
                    value="" />
                <input
                    id="cas_import_map_groups_quota_first"
                    class="cas_import_map_groups_quota"
                    value="" />
                <button id="addFilterGroup" type="button" style="width: 34px;">+</button>
            </div>
        </div>

        <div class="footer-actions">
            <input type="submit" value="Enregistrer" />
        </div>
    </div>

    <div class="section">
        <h2>Groupes pédagogiques</h2>
        <p>
            Informations sur la syntaxe de nommage : Le champs de nommage utilise la syntaxe des littéraux de gabarits ${maVariable}, de plus vous pouvez utiliser la variable ${nomEtablissement} pour insérer le nom de l'établissement dans le nommage
        </p>

        <div>
            <input
                id="cas_import_map_groups_pedagogic"
                name="cas_import_map_groups_pedagogic"
                value="<?php p($_['cas_import_map_groups_pedagogic']); ?>"
                data-value="<?php p($_['cas_import_map_groups_pedagogic']); ?>"
                style="display: none;width: 100%;" />
            <div style="display: grid;grid-template-columns: 1fr 1fr 3fr;column-gap: 4px;" class="cw-100">
                <label>Nom de l'attribut LDAP des utilisteurs</label>
                <label>Regex de filtre</label>
                <label>Nommage</label>
                <input
                    id="cas_import_map_groups_pedagogic_first"
                    class="cas_import_map_groups_pedagogic"
                    value="" />
                <input
                    id="cas_import_map_groups_pedagogic_filter_first"
                    class="cas_import_map_groups_pedagogic_filter"
                    value="" />
                <input
                    id="cas_import_map_groups_pedagogic_naming_first"
                    class="cas_import_map_groups_pedagogic_naming"
                    value="" />
                <button id="addPedagogicGroup" type="button" style="width: 34px;">+</button>
            </div>
        </div>

        <div class="footer-actions">
            <input type="submit" value="Enregistrer" />
        </div>
    </div>
    <input type="hidden" value="<?php p($_['requesttoken']); ?>" name="requesttoken" />
</form>