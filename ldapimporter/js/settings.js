$(document).ready(function () {

    const computeHiddenFields = function () {
        let pegadogicGroups = {};
        $('.cas_import_map_groups_pedagogic').each(function (i) {
            const value = $(this).val();
            if (value.length > 0) {
                pegadogicGroups[i] = {
                    ...pegadogicGroups[i],
                    'field': value
                }
            }
        })
        $('.cas_import_map_groups_pedagogic_filter').each(function (i) {
            const value = $(this).val();
            if (value.length > 0) {
                pegadogicGroups[i] = {
                    ...pegadogicGroups[i],
                    'filter': value
                }
            }
        })
        $('.cas_import_map_groups_pedagogic_naming').each(function (i) {
            const value = $(this).val();
            if (value.length > 0) {
                pegadogicGroups[i] = {
                    ...pegadogicGroups[i],
                    'naming': value
                }
            }
        })

        let filterGroups = {};
        $('.cas_import_map_groups_filter').each(function (i) {
            const value = $(this).val();
            if (value.length > 0) {
                filterGroups[i] = {
                    ...filterGroups[i],
                    'filter': value
                }
            }
        })
        $('.cas_import_map_groups_naming').each(function (i) {
            const value = $(this).val();
            if (value.length > 0) {
                filterGroups[i] = {
                    ...filterGroups[i],
                    'naming': value
                }
            }
        })
        $('.cas_import_map_groups_quota').each(function (i) {
            const value = $(this).val();
            if (value.length > 0) {
                filterGroups[i] = {
                    ...filterGroups[i],
                    'quota': value
                }
            }
        })
        $('.cas_import_map_groups_uai_number').each(function (i) {
            const value = $(this).val();
            if (value.length > 0) {
                filterGroups[i] = {
                    ...filterGroups[i],
                    'uaiNumber': value
                }
            }
        })

        let nameUaiGroup = {};
        $('.cas_import_regex_name_uai').each(function (i) {
            const value = $(this).val();
            if (value.length > 0) {
                nameUaiGroup[i] = {
                    ...nameUaiGroup[i],
                    'nameUai': value
                }
            }
        })
        $('.cas_import_regex_name_group').each(function (i) {
            const value = $(this).val();
            if (value.length > 0) {
                nameUaiGroup[i] = {
                    ...nameUaiGroup[i],
                    'nameGroup': value
                }
            }
        })
        $('.cas_import_regex_uai_group').each(function (i) {
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

    $('#cas_import_ad_sync_pagesize').on('change', function () {
        console.log($(this).val());
        $("#cas_import_ad_sync_pagesize_value").val($(this).val());
    });

    $('#cas_import_ad_sync_pagesize_value').on('keyup', function () {
        console.log($(this).val());
        $("#cas_import_ad_sync_pagesize").val($(this).val());
    });

    const addPedagogicGroupLine = function (field = '', filter = '', naming = '') {
        $('#pedagogicGroup > tbody').append(
            "<tr>" +
            "<td><input class=\"cas_import_map_groups_pedagogic\" value='" + field + "'/></td>" +
            "<td><input class=\"cas_import_map_groups_pedagogic_filter\" value='" + filter + "'/></td>" +
            "<td><input class=\"cas_import_map_groups_pedagogic_naming\" value='" + naming + "'/></td>" +
            "<td>" +
            "<button class=\"moveUpPedagogicGroup\" type=\"button\" title=\"Monter\" style=\"width: 34px;\">↑</button>" +
            "<button class=\"moveDownPedagogicGroup\" type=\"button\" title=\"Descendre\" style=\"width: 34px;\">↓</button>" +
            "<button class=\"removePedagogicGroup\" type=\"button\" title=\"Supprimer\" style=\"width: 34px;\">×</button>" +
            "</td>" +
            "</tr>"
        );
    }

    const importMapGroupsPedagogic = $('#cas_import_map_groups_pedagogic').val();
    if (importMapGroupsPedagogic.length > 0) {
        let parsedPedagogicGroups = null;
        try {
            parsedPedagogicGroups = JSON.parse(decodeHTMLEntities(importMapGroupsPedagogic))
        } catch (e) {
            parsedPedagogicGroups = []
        }
        Object.entries(parsedPedagogicGroups).forEach(function ([key, pedagogicGroup], i) {
            if (i === 0) {
                $('#cas_import_map_groups_pedagogic_first').val(pedagogicGroup.field)
                $('#cas_import_map_groups_pedagogic_filter_first').val(pedagogicGroup.filter)
                $('#cas_import_map_groups_pedagogic_naming_first').val(pedagogicGroup.naming)
            }
            else {
                const field = pedagogicGroup.field ? pedagogicGroup.field : '';
                const filter = pedagogicGroup.filter ? pedagogicGroup.filter : '';
                const naming = pedagogicGroup.naming ? pedagogicGroup.naming : '';
                addPedagogicGroupLine(field, filter, naming)
            }
        });
    }

    $('#addPedagogicGroup').on('click', function () {
        addPedagogicGroupLine()
    });

    $('#pedagogicGroup > tbody')
        .on('click', '.moveUpPedagogicGroup', function () {
            const row = $(this).closest('tr')
            row.prev().before(row);
        })
        .on('click', '.moveDownPedagogicGroup', function () {
            const row = $(this).closest('tr')
            row.next().after(row)
        })
        .on('click', '.removePedagogicGroup', function () {
            $(this).closest('tr').remove()
        })

    const addFilterGroupLine = function (filter = '', naming = '', quota = '', uaiNumber = '') {
        $('#filterGroup > tbody').append(
            "<tr>" +
            "<td><input class=\"cas_import_map_groups_filter\" value='" + filter + "'/></td>" +
            "<td><input class=\"cas_import_map_groups_naming\" value='" + naming + "'/></td>" +
            "<td><input class=\"cas_import_map_groups_uai_number\" value='" + uaiNumber + "'/></td>" +
            "<td><input class=\"cas_import_map_groups_quota\" value='" + quota + "'/></td>" +
            "<td>" +
            "<button class=\"moveUpFilterGroup\" type=\"button\" title=\"Monter\" style=\"width: 34px;\">↑</button>" +
            "<button class=\"moveDownFilterGroup\" type=\"button\" title=\"Descendre\" style=\"width: 34px;\">↓</button>" +
            "<button class=\"removeFilterGroup\" type=\"button\" title=\"Supprimer\" style=\"width: 34px;\">×</button>" +
            "</td>" +
            "</tr>"
        );
    }

    const importMapFilterGroups = $('#cas_import_map_groups_fonctionel').val();
    if (importMapFilterGroups.length > 0) {
        let parsedFilterGroups = null;
        try {
            parsedFilterGroups = JSON.parse(decodeHTMLEntities(importMapFilterGroups))
        } catch (e) {
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
                addFilterGroupLine(filter, naming, quota, uaiNumber)
            }
        });
    }

    $('#addFilterGroup').on('click', function () {
        addFilterGroupLine()
    });

    $('#filterGroup > tbody')
        .on('click', '.moveUpFilterGroup', function () {
            const row = $(this).closest('tr')
            row.prev().before(row);
        })
        .on('click', '.moveDownFilterGroup', function () {
            const row = $(this).closest('tr')
            row.next().after(row)
        })
        .on('click', '.removeFilterGroup', function () {
            $(this).closest('tr').remove()
        })

    const addNameUaiGroupLine = function (nameUai = '', nameGroup = '', uaiGroup = '') {
        $('#nameUaiGroup > tbody').append(
            "<tr>" +
            "<td><input class=\"cas_import_regex_name_uai\" value=\"" + nameUai + "\"/></td>" +
            "<td><input class=\"cas_import_regex_name_group\" value=\"" + nameGroup + "\"/></td>" +
            "<td><input class=\"cas_import_regex_uai_group\" value=\"" + uaiGroup + "\"/></td>" +
            "<td>" +
            "<button class=\"moveUpNameUaiGroup\" type=\"button\" title=\"Monter\" style=\"width: 34px;\">↑</button>" +
            "<button class=\"moveDownNameUaiGroup\" type=\"button\" title=\"Descendre\" style=\"width: 34px;\">↓</button>" +
            "<button class=\"removeNameUaiGroup\" type=\"button\" title=\"Supprimer\" style=\"width: 34px;\">×</button>" +
            "</td>" +
            "</tr>"
        );
    }

    const importNameUaiGroups = $('#cas_import_map_regex_name_uai').val();
    if (importNameUaiGroups.length > 0) {
        let parsedNameUaiGroups = null;
        try {
            parsedNameUaiGroups = JSON.parse(decodeHTMLEntities(importNameUaiGroups))
        } catch (e) {
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
                addNameUaiGroupLine(nameUai, nameGroup, uaiGroup)
            }
        });
    }

    $('#addNameUaiGroup').on('click', function () {
        addNameUaiGroupLine()
    });

    $('#nameUaiGroup > tbody')
        .on('click', '.moveUpNameUaiGroup', function () {
            const row = $(this).closest('tr')
            row.prev().before(row);
        })
        .on('click', '.moveDownNameUaiGroup', function () {
            const row = $(this).closest('tr')
            row.next().after(row)
        })
        .on('click', '.removeNameUaiGroup', function () {
            $(this).closest('tr').remove()
        })
});

function decodeHTMLEntities(text) {
    var textArea = document.createElement('textarea');
    textArea.innerHTML = text;
    return textArea.value;
}
