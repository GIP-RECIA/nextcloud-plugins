$(document).ready(function () {

    $('#ldapimporter #casSettings').tabs();


    $("#ldapimporter #cas_force_login").on('change', function (event) {

        if ($(this).is(':checked')) {

            $("#ldapimporter #cas_disable_logout").attr("disabled", true);
            $("#ldapimporter #cas_disable_logout").prop('checked', false);

            $("#ldapimporter #cas_force_login_exceptions").attr("disabled", false);
        } else {

            $("#ldapimporter #cas_disable_logout").attr("disabled", false);
            $("#ldapimporter #cas_force_login_exceptions").attr("disabled", true);
        }
    });

    $("#ldapimporter #cas_disable_logout").on('change', function (event) {

        if ($(this).is(':checked')) {

            $("#ldapimporter #cas_handlelogout_servers").attr("disabled", true);
        } else {

            $("#ldapimporter #cas_handlelogout_servers").attr("disabled", false);
        }
    });

    $("#ldapimporter #importSettingsSubmit").on('click', function (event) {

        event.preventDefault();

        //console.log("Submit button clicked.");

        var postData = $('#ldapimporter').serialize();
        var method = $('#ldapimporter').attr('method');
        var url = OC.generateUrl('/apps/ldapimporter/settings/save');
        console.log(postData, url)

        $.ajax({
            method: method,
            url: url,
            data: postData,
            success: function (data) {

                var notification = OC.Notification.show(data.message);

                setTimeout(function () {
                    OC.Notification.hide(notification);
                }, 5000);

            },
            error: function (data) {
                console.log(data)
                var notification = OC.Notification.show(data.message);

                setTimeout(function () {
                    OC.Notification.hide(notification);
                }, 5000);
            }
        });
    });


    $('input[type=range]').on('input', function () {
        $(this).trigger('change');
    });

    $('#cas_import_ad_sync_pagesize').on ('change', function() {

        console.log($(this).val());
        $("#cas_import_ad_sync_pagesize_value").val($(this).val());
    });

    $('#cas_import_ad_sync_pagesize_value').on('keyup', function() {

        console.log($(this).val());
        $("#cas_import_ad_sync_pagesize").val($(this).val());
    });



    const importMapGroupsPedagogic = $('#cas_import_map_groups_pedagogic').val();
    if (importMapGroupsPedagogic.length > 0) {
        let parsedPedagogicGroups = null;
        try {
            parsedPedagogicGroups = JSON.parse(decodeHTMLEntities(importMapGroupsPedagogic))
        } catch(e) {
            parsedPedagogicGroups = []
        }
        Object.entries(parsedPedagogicGroups).forEach(function([key, pedagogicGroup], i) {
            if (i === 0) {
                $('#cas_import_map_groups_pedagogic_first').val(pedagogicGroup.field)
                $('#cas_import_map_groups_pedagogic_filter_first').val(pedagogicGroup.filter)
                $('#cas_import_map_groups_pedagogic_naming_first').val(pedagogicGroup.naming)
            }
            else {
                const field = pedagogicGroup.field ? pedagogicGroup.field : '';
                const filter = pedagogicGroup.filter ? pedagogicGroup.filter : '';
                const naming = pedagogicGroup.naming ? pedagogicGroup.naming : '';
                $('#addPedagogicGroup').before("<div style=\"display: flex;\">" +
                    "<p style=\"width: 25%\"><label>Nom de l'attribut LDAP</label>" +
                        "<input " +
                                " style=\"width: 90%\"" +
                                " class=\"cas_import_map_groups_pedagogic\"" +
                                " value='" + field + "'" +
                                " placeholder=\"Nom de l'attribut LDAP\"/>" +
                    " </p>" +
                    "<p style=\"width: 50%\"><label>Regex de filtre</label>" +
                        "<input " +
                                " style=\"width: 90%\"" +
                                " class=\"cas_import_map_groups_pedagogic_filter\"" +
                                " value='" + filter + "'" +
                                " placeholder=\"Regex de filtre\"/>" +
                    " </p>" +
                    "<p style=\"width: 25%\"><label>Nommage</label>" +
                        "<input " +
                                " style=\"width: 90%\"" +
                                " class=\"cas_import_map_groups_pedagogic_naming\"" +
                                " value='" + naming + "'" +
                                " placeholder=\"Nommage\"/>" +
                    " </p>" +
                "</div>");
            }
        });
    }

    const importMapFilterGroups = $('#cas_import_map_groups_fonctionel').val();
    if (importMapFilterGroups.length > 0) {
        let parsedFilterGroups = null;
        try {
            parsedFilterGroups = JSON.parse(decodeHTMLEntities(importMapFilterGroups))
        } catch(e) {
            parsedFilterGroups = []
        }
        Object.entries(parsedFilterGroups).forEach(function ([key, fonctionnelGroup], i) {
            if (i === 0) {
                $('#cas_import_map_groups_filter_first').val(fonctionnelGroup.filter);
                $('#cas_import_map_groups_naming_first').val(fonctionnelGroup.naming)
                $('#cas_import_map_groups_quota_first').val(fonctionnelGroup.quota)
                $('#cas_import_map_groups_uai_number_first').val(fonctionnelGroup.uaiNumber)
            }
            else {
                const filter = fonctionnelGroup.filter ? fonctionnelGroup.filter : '';
                const naming = fonctionnelGroup.naming ? fonctionnelGroup.naming : '';
                const quota = fonctionnelGroup.quota ? fonctionnelGroup.quota : '';
                const uaiNumber = fonctionnelGroup.uaiNumber ? fonctionnelGroup.uaiNumber : '';
                $('#addFilterGroup').before("<div style=\"display: flex;\">" +
                    "<p><label>Regex de filtre</label>" +
                    "<input " +
                    " style=\"width: 90%\"" +
                    " class=\"cas_import_map_groups_filter\"" +
                    " value='" + filter + "'" +
                    " placeholder=\"Regex de filtre\"/>" +
                    " </p>" +
                    "<p><label>Nommage</label>" +
                    "<input " +
                    " style=\"width: 90%\"" +
                    " class=\"cas_import_map_groups_naming\"" +
                    " value='" + naming + "'" +
                    " placeholder=\"Nommage\"/>" +
                    " </p>" +
                    "<p><label>Numéro du groupement de la regex pour l'UAI ou le nom</label>" +
                    "<input " +
                    " style=\"width: 90%\"" +
                    " class=\"cas_import_map_groups_uai_number\"" +
                    " value='" + uaiNumber + "'" +
                    " placeholder=\"Numéro du groupement de la regex pour l'UAI ou le nom\"/>" +
                    " </p>" +
                    "<p><label>Quota (en GB)</label>" +
                    "<input " +
                    " style=\"width: 90%\"" +
                    " class=\"cas_import_map_groups_quota\"" +
                    " value='" + quota + "'" +
                    " placeholder=\"Quota\"/>" +
                    " </p>" +
                    "</div>");
            }

        });
    }

    const importNameUaiGroups = $('#cas_import_map_regex_name_uai').val();
    if (importNameUaiGroups.length > 0) {
        let parsedNameUaiGroups = null;
        try {
            parsedNameUaiGroups = JSON.parse(decodeHTMLEntities(importNameUaiGroups))
        } catch(e) {
            parsedNameUaiGroups = []
        }
        Object.entries(parsedNameUaiGroups).forEach(function ([key, group], i) {
            if (i === 0) {
                $('#cas_import_regex_name_uai_first').val(group.nameUai);
                $('#cas_import_regex_name_group_first').val(group.nameGroup)
                $('#cas_import_regex_uai_group_first').val(group.uaiGroup)
            }
            else {
                const nameUai = group.nameUai ? group.nameUai : '';
                const nameGroup = group.nameGroup ? group.nameGroup : '';
                const uaiGroup = group.uaiGroup ? group.uaiGroup : '';
                $('#addNameUaiGroup').before("<div style=\"display: flex;justify-content: space-between\">\n" +
                    "                    <div style=\"width: 40%\">\n" +
                    "                        <label style=\"width: 100%\" for=\"cas_import_regex_name_uai\">Regex de nommage d'établissement et du UAI</label>\n" +
                    "                        <p style=\"color: gray\">Les groupements de la regex pour le nom et l'UAI de l'établissement sont défini ci-contre</p>\n" +
                    "                        <input\n" +
                    "                                style=\"width: 100%\"\n" +
                    "                                class=\"cas_import_regex_name_uai\"\n" +
                    "                                value=\"" + nameUai + "\" placeholder=\"Regex de nommage d'établissement et du UAI\"/>\n" +
                    "                    </div>\n" +
                    "                    <div style=\"width: 25%\">\n" +
                    "                        <label style=\"width: 100%\" for=\"cas_import_regex_name_group\">Numéro du groupement dans la regex correspondant au nom de l'établissement</label>\n" +
                    "                        <p style=\"color: gray\"></p>\n" +
                    "                        <input\n" +
                    "                                style=\"width: 100%\"\n" +
                    "                                class=\"cas_import_regex_name_group\"\n" +
                    "                                value=\"" + nameGroup + "\" placeholder=\"Numéro du groupement dans la regex correspondant au nom de l'établissement\"/>\n" +
                    "                    </div>\n" +
                    "                    <div style=\"width: 25%\">\n" +
                    "                        <label style=\"width: 100%\" for=\"cas_import_regex_uai_group\">Numéro du groupement dans la regex correspondant à l'UAI de l'établissement</label>\n" +
                    "                        <p style=\"color: gray\"></p>\n" +
                    "                        <input\n" +
                    "                                style=\"width: 100%\"\n" +
                    "                                class=\"cas_import_regex_uai_group\"\n" +
                    "                                value=\"" + uaiGroup + "\" placeholder=\"Numéro du groupement dans la regex correspondant à l'UAI de l'établissement\"/>\n" +
                    "                    </div>\n" +
                    "                </div>");
            }

        });
    }

    $('#addPedagogicGroup').on('click', function() {

        $('#addPedagogicGroup').before("<div style=\"display: flex;\">" +
            "<p style=\"width: 25%\"><label>Nom de l'attribut LDAP</label>" +
                "<input " +
                        " style=\"width: 90%\"" +
                        " class=\"cas_import_map_groups_pedagogic\"" +
                        " placeholder=\"Nom de l'attribut LDAP\"/>" +
            " </p>" +
            "<p style=\"width: 50%\"><label>Regex de filtre</label>" +
                "<input " +
                        " style=\"width: 90%\"" +
                        " class=\"cas_import_map_groups_pedagogic_filter\"" +
                        " placeholder=\"Regex de filtre\"/>" +
            " </p>" +
            "<p style=\"width: 25%\"><label>Nommage</label>" +
            "<input " +
                    " style=\"width: 90%\"" +
                    " class=\"cas_import_map_groups_pedagogic_naming\"" +
                    " placeholder=\"Nommage\"/>" +
        " </p>" +

        "</div>");
    });

    $('#addNameUaiGroup').on('click', function() {

        $('#addNameUaiGroup').before("<div style=\"display: flex;justify-content: space-between\">" +
            "                    <div style=\"width: 40%\">" +
            "                        <label style=\"width: 100%\" for=\"cas_import_regex_name_uai\">Regex de nommage d'établissement et du UAI</label>" +
            "                        <p style=\"color: gray\">Les groupements de la regex pour le nom et l'UAI de l'établissement sont défini ci-contre</p>" +
            "                        <input style=\"width: 100%\" class=\"cas_import_regex_name_uai\" placeholder=\"Regex de nommage d'établissement et du UAI\"/>" +
            "                    </div>" +
            "                    <div style=\"width: 25%\">\n" +
            "                        <label style=\"width: 100%\" for=\"cas_import_regex_name_group\">Numéro du groupement dans la regex correspondant au nom de l'établissement</label>\n" +
            "                        <p style=\"color: gray\"></p>" +
            "                        <input style=\"width: 100%\" class=\"cas_import_regex_name_group\"" +
            "                               placeholder=\"Numéro du groupement dans la regex correspondant au nom de l'établissement\"/>" +
            "                    </div>" +
            "                    <div style=\"width: 25%\">" +
            "                        <label style=\"width: 100%\" for=\"cas_import_regex_uai_group\">Numéro du groupement dans la regex correspondant à l'UAI de l'établissement</label>\n" +
            "                        <p style=\"color: gray\"></p>" +
            "                        <input style=\"width: 100%\" class=\"cas_import_regex_uai_group\" placeholder=\"Numéro du groupement dans la regex correspondant à l'UAI de l'établissement\"/>" +
            "                    </div>" +
            "                </div>");
    });


    $('#importSettingsSubmit').on('mouseover', function() {
        let pegadogicGroups = {};
        $('.cas_import_map_groups_pedagogic').each(function(i) {
            const value = $(this).val();
            if (value.length > 0) {
                pegadogicGroups[i] = {
                    ...pegadogicGroups[i],
                    'field': value
                }
            }
        })
        $('.cas_import_map_groups_pedagogic_filter').each(function(i) {
            const value = $(this).val();
            if (value.length > 0) {
                pegadogicGroups[i] = {
                    ...pegadogicGroups[i],
                    'filter': value
                }
            }
        })
        $('.cas_import_map_groups_pedagogic_naming').each(function(i) {
            const value = $(this).val();
            if (value.length > 0) {
                pegadogicGroups[i] = {
                    ...pegadogicGroups[i],
                    'naming': value
                }
            }
        })

        let filterGroups = {};
        $('.cas_import_map_groups_filter').each(function(i) {
            const value = $(this).val();
            if (value.length > 0) {
                filterGroups[i] = {
                    ...filterGroups[i],
                    'filter': value
                }
            }
        })
        $('.cas_import_map_groups_naming').each(function(i) {
            const value = $(this).val();
            if (value.length > 0) {
                filterGroups[i] = {
                    ...filterGroups[i],
                    'naming': value
                }
            }
        })
        $('.cas_import_map_groups_quota').each(function(i) {
            const value = $(this).val();
            if (value.length > 0) {
                filterGroups[i] = {
                    ...filterGroups[i],
                    'quota': value
                }
            }
        })
        $('.cas_import_map_groups_uai_number').each(function(i) {
            const value = $(this).val();
            if (value.length > 0) {
                filterGroups[i] = {
                    ...filterGroups[i],
                    'uaiNumber': value
                }
            }
        })


        let nameUaiGroup = {};
        $('.cas_import_regex_name_uai').each(function(i) {
            const value = $(this).val();
            if (value.length > 0) {
                nameUaiGroup[i] = {
                    ...nameUaiGroup[i],
                    'nameUai': value
                }
            }
        })
        $('.cas_import_regex_name_group').each(function(i) {
            const value = $(this).val();
            if (value.length > 0) {
                nameUaiGroup[i] = {
                    ...nameUaiGroup[i],
                    'nameGroup': value
                }
            }
        })
        $('.cas_import_regex_uai_group').each(function(i) {
            const value = $(this).val();
            if (value.length > 0) {
                nameUaiGroup[i] = {
                    ...nameUaiGroup[i],
                    'uaiGroup': value
                }
            }
        })


        $('#cas_import_map_groups_fonctionel').val(JSON.stringify(filterGroups));
        $('#cas_import_map_groups_pedagogic').val(JSON.stringify(pegadogicGroups));
        $('#cas_import_map_regex_name_uai').val(JSON.stringify(nameUaiGroup));

    });

    $('#addFilterGroup').on('click', function() {

        $('#addFilterGroup').before("<div style=\"display: flex;\">" +
            "<p><label>Regex de filtre</label>" +
            "<input " +
            " style=\"width: 90%\"" +
            " class=\"cas_import_map_groups_filter\"" +
            " placeholder=\"Regex de filtre\"/>" +
            " </p>" +
            "<p><label>Nommage</label>" +
            "<input " +
            " style=\"width: 90%\"" +
            " class=\"cas_import_map_groups_naming\"" +
            " placeholder=\"Nommage\"/>" +
            " </p>" +
            "<p><label>Numéro du groupement de la regex pour l'UAI ou le nom</label>" +
            "<input " +
            " style=\"width: 90%\"" +
            " class=\"cas_import_map_groups_uai_number\"" +
            " placeholder=\"Numéro du groupement de la regex pour l'UAI ou le nom\"/>" +
            " </p>" +
            "<p><label>Quota (en GB)</label>" +
            "<input " +
            " style=\"width: 90%\"" +
            " class=\"cas_import_map_groups_quota\"" +
            " placeholder=\"Quota\"/>" +
            " </p>" +
            "</div>");
    });
});

function decodeHTMLEntities(text) {
    var textArea = document.createElement('textarea');
    textArea.innerHTML = text;
    return textArea.value;
}