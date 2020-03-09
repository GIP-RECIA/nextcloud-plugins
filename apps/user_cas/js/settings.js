$(document).ready(function () {

    $('#user_cas #casSettings').tabs();


    $("#user_cas #cas_force_login").on('change', function (event) {

        if ($(this).is(':checked')) {

            $("#user_cas #cas_disable_logout").attr("disabled", true);
            $("#user_cas #cas_disable_logout").prop('checked', false);

            $("#user_cas #cas_force_login_exceptions").attr("disabled", false);
        } else {

            $("#user_cas #cas_disable_logout").attr("disabled", false);
            $("#user_cas #cas_force_login_exceptions").attr("disabled", true);
        }
    });

    $("#user_cas #cas_disable_logout").on('change', function (event) {

        if ($(this).is(':checked')) {

            $("#user_cas #cas_handlelogout_servers").attr("disabled", true);
        } else {

            $("#user_cas #cas_handlelogout_servers").attr("disabled", false);
        }
    });

    $("#user_cas #casSettingsSubmit").on('click', function (event) {

        event.preventDefault();

        //console.log("Submit button clicked.");

        var postData = $('#user_cas').serialize();
        var method = $('#user_cas').attr('method');
        var url = OC.generateUrl('/apps/user_cas/settings/save');
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
        Object.entries(JSON.parse(importMapGroupsPedagogic.replace(/&quot;/g,'"'))).forEach(function([key, pedagogicGroup], i) {
            console.log(pedagogicGroup)
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
                    "<p><label>Nom de l'attribut LDAP</label>" +
                        "<input " +
                                " style=\"width: 65%\"" +
                                " class=\"cas_import_map_groups_pedagogic\"" +
                                " value='" + field + "'" +
                                " placeholder=\"Nom de l'attribut LDAP\"/>" +
                    " </p>" +
                    "<p><label>Regex de filtre</label>" +
                        "<input " +
                                " style=\"width: 65%\"" +
                                " class=\"cas_import_map_groups_pedagogic_filter\"" +
                                " value='" + filter + "'" +
                                " placeholder=\"Regex de filtre\"/>" +
                    " </p>" +
                    "<p><label>Nommage</label>" +
                        "<input " +
                                " style=\"width: 65%\"" +
                                " class=\"cas_import_map_groups_pedagogic_naming\"" +
                                " value='" + naming + "'" +
                                " placeholder=\"Nommage\"/>" +
                    " </p>" +
                "</div>");
            }
        });
    }

    $('#addPedagogicGroup').on('click', function() {
        $('#addPedagogicGroup').before("<div style=\"display: flex;\">" +
            "<p><label>Nom de l'attribut LDAP</label>" +
                "<input " +
                        " style=\"width: 65%\"" +
                        " class=\"cas_import_map_groups_pedagogic\"" +
                        " placeholder=\"Nom de l'attribut LDAP\"/>" +
            " </p>" +
            "<p><label>Regex de filtre</label>" +
                "<input " +
                        " style=\"width: 65%\"" +
                        " class=\"cas_import_map_groups_pedagogic_filter\"" +
                        " placeholder=\"Regex de filtre\"/>" +
            " </p>" +
            "<p><label>Nommage</label>" +
            "<input " +
                    " style=\"width: 65%\"" +
                    " class=\"cas_import_map_groups_pedagogic_naming\"" +
                    " placeholder=\"Nommage\"/>" +
        " </p>" +

        "</div>");
    });
    $('#casSettingsSubmit').on('mouseover', function() {
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
        console.log(JSON.stringify(pegadogicGroups))
        $('#cas_import_map_groups_pedagogic').val(JSON.stringify(pegadogicGroups));
    });
});