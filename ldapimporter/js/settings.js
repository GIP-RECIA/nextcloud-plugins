$(document).ready(function () {

    const computeHiddenFields = function() {
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
    };

    $("form#ldapimporter").on('submit', function (event) {
        event.preventDefault();
        computeHiddenFields();
        setTimeout(() => {
            var postData = $('#ldapimporter').serialize();
            var method = $('#ldapimporter').attr('method');
            var url = OC.generateUrl('/apps/ldapimporter/settings/save');
            console.log(postData)

            var infoNotification = OC.Notification.show("Sauvegarde en cours");
    
            $.ajax({
                method: method,
                url: url,
                data: postData,
                success: function (data) {
                    OC.Notification.hide(infoNotification);
                    var notification = OC.Notification.show(data.message);
                    setTimeout(function () {
                        OC.Notification.hide(notification);
                    }, 5000);
                },
                error: function (data) {
                    OC.Notification.hide(infoNotification);
                    console.log(data)
                    var notification = OC.Notification.show(data.message);
                    setTimeout(function () {
                        OC.Notification.hide(notification);
                    }, 5000);
                }
            });
        }, 500)
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
                $('#addPedagogicGroup').before(
                    "<input " +
                    " class=\"cas_import_map_groups_pedagogic\"" +
                    " value='" + field + "'/>" +
                    "<input " +
                    " class=\"cas_import_map_groups_pedagogic_filter\"" +
                    " value='" + filter + "'/>" +
                    "<input " +
                    " class=\"cas_import_map_groups_pedagogic_naming\"" +
                    " value='" + naming + "'/>");
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
                $('#addFilterGroup').before(
                    "<input " +
                    " class=\"cas_import_map_groups_filter\"" +
                    " value='" + filter + "'/>" +
                    "<input " +
                    " class=\"cas_import_map_groups_naming\"" +
                    " value='" + naming + "'/>" +
                    "<input " +
                    " class=\"cas_import_map_groups_uai_number\"" +
                    " value='" + uaiNumber + "'/>" +
                    "<input " +
                    " class=\"cas_import_map_groups_quota\"" +
                    " value='" + quota + "'/>");
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
                $('#addNameUaiGroup').before(
                    "                        <input\n" +
                    "                                class=\"cas_import_regex_name_uai\"\n" +
                    "                                value=\"" + nameUai + "\"/>\n" +
                    "                        <input\n" +
                    "                                class=\"cas_import_regex_name_group\"\n" +
                    "                                value=\"" + nameGroup + "\"/>\n" +
                    "                        <input\n" +
                    "                                class=\"cas_import_regex_uai_group\"\n" +
                    "                                value=\"" + uaiGroup + "\"/>\n");
            }

        });
    }

    $('#addPedagogicGroup').on('click', function() {
        $('#addPedagogicGroup').before(
            "<input " +
            " class=\"cas_import_map_groups_pedagogic\"/>" +
            "<input " +
            " class=\"cas_import_map_groups_pedagogic_filter\"/>" +
            "<input " +
            " class=\"cas_import_map_groups_pedagogic_naming\"/>");
    });

    $('#addNameUaiGroup').on('click', function() {
        $('#addNameUaiGroup').before(
            "                        <input class=\"cas_import_regex_name_uai\"/>" +
            "                        <input class=\"cas_import_regex_name_group\"/>" +
            "                        <input class=\"cas_import_regex_uai_group\"/>");
    });

    $('#addFilterGroup').on('click', function() {
        $('#addFilterGroup').before(
            "<input " +
            " class=\"cas_import_map_groups_filter\"/>" +
            "<input " +
            " class=\"cas_import_map_groups_naming\"/>" +
            "<input " +
            " class=\"cas_import_map_groups_uai_number\"/>" +
            "<input " +
            " class=\"cas_import_map_groups_quota\"/>");
    });
});

function decodeHTMLEntities(text) {
    var textArea = document.createElement('textarea');
    textArea.innerHTML = text;
    return textArea.value;
}