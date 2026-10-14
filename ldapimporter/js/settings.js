document.addEventListener('DOMContentLoaded', () => {
    pagesizeInteractions();
    importMapPedagogicGroup();
    pedagogicGroupInteractions();
    importMapFilterGroup();
    filterGroupInteractions();
    importMapNameUaiGroup();
    nameUaiGroupInteractions();

    document.querySelector("form#ldapimporter").addEventListener('submit', (event) => {
        event.preventDefault();
        computeHiddenFields();
        setTimeout(async () => {
            const form = document.querySelector('#ldapimporter');
            const postData = new URLSearchParams(new FormData(form));
            const method = form.getAttribute('method');
            const url = OC.generateUrl('/apps/ldapimporter/settings/save');

            console.log(postData.toString());

            const infoNotification = OC.Notification.show('Sauvegarde en cours');

            try {
                const response = await fetch(url, {
                    method,
                    body: postData,
                });

                if (!response.ok)
                    throw new Error(`Erreur HTTP : ${response.status}`);
                const data = await response.json();

                OC.Notification.hide(infoNotification);
                const notification = OC.Notification.show(data.message);
                setTimeout(() => {
                    OC.Notification.hide(notification);
                }, 5000);
            } catch (error) {
                OC.Notification.hide(infoNotification);
                console.error(error);
                const notification = OC.Notification.show('Erreur lors de la sauvegarde');
                setTimeout(() => {
                    OC.Notification.hide(notification);
                }, 5000);
            }
        }, 500);
    });
});

function decodeHTMLEntities(text) {
    var textArea = document.createElement('textarea');
    textArea.innerHTML = text;
    return textArea.value;
}

function pagesizeInteractions() {
    const pagesize = document.querySelector('#cas_import_ad_sync_pagesize');
    const pagesizeValue = document.querySelector('#cas_import_ad_sync_pagesize_value');

    pagesize.addEventListener('input', () => {
        pagesizeValue.value = pagesize.value;
    });

    pagesizeValue.addEventListener('input', () => {
        pagesize.value = pagesizeValue.value;
    });
}

// PedagogicGroup

function importMapPedagogicGroup() {
    const importMapGroupsPedagogic = document.querySelector('#cas_import_map_groups_pedagogic').value;
    if (importMapGroupsPedagogic.length > 0) {
        let parsedPedagogicGroups = null;
        try {
            parsedPedagogicGroups = JSON.parse(decodeHTMLEntities(importMapGroupsPedagogic));
        } catch (e) {
            parsedPedagogicGroups = [];
        }
        Object.entries(parsedPedagogicGroups).forEach(([_, pedagogicGroup]) => {
            const field = pedagogicGroup.field ? pedagogicGroup.field : '';
            const filter = pedagogicGroup.filter ? pedagogicGroup.filter : '';
            const naming = pedagogicGroup.naming ? pedagogicGroup.naming : '';
            addPedagogicGroupLine(field, filter, naming);
        });
    }
}

function pedagogicGroupInteractions() {
    const pedagogicGroupTbody = document.querySelector('#pedagogicGroup > tbody');
    pedagogicGroupTbody.addEventListener('click', (event) => {
        const button = event.target;
        const row = button.closest('tr');
        switch (button.className) {
            case 'moveUpPedagogicGroup':
                row?.previousElementSibling?.before(row);
                break;
            case 'moveDownPedagogicGroup':
                row?.nextElementSibling?.after(row);
                break;
            case 'removePedagogicGroup':
                row?.remove();
                break;
        }
    });

    document.querySelector('#addPedagogicGroup').addEventListener('click', () => {
        addPedagogicGroupLine();
    });
}

function addPedagogicGroupLine(field = '', filter = '', naming = '') {
    const line = document.createElement('tr');
    line.innerHTML = `
        <td>
            <input
                value="${field}"
                class="cas_import_map_groups_pedagogic"
            />
        </td>
        <td>
            <input
                value="${filter}"
                class="cas_import_map_groups_pedagogic_filter"
            />
        </td>
        <td>
            <input
                value="${naming}"
                class="cas_import_map_groups_pedagogic_naming"
            />
        </td>
        <td>
            <button
                type="button"
                title="Monter"
                class="moveUpPedagogicGroup"
                style="width: 34px;"
            >
                ↑
            </button>
            <button
                type="button"
                title="Descendre"
                class="moveDownPedagogicGroup"
                style="width: 34px;"
            >
                ↓
            </button>
            <button
                type="button"
                title="Supprimer"
                class="removePedagogicGroup"
                style="width: 34px;"
            >
                ×
            </button>
        </td>
    `;
    document.querySelector('#pedagogicGroup > tbody').append(line);
}

// FilterGroup

function importMapFilterGroup() {
    const importMapFilterGroups = document.querySelector('#cas_import_map_groups_fonctionel').value;
    if (importMapFilterGroups.length > 0) {
        let parsedFilterGroups = null;
        try {
            parsedFilterGroups = JSON.parse(decodeHTMLEntities(importMapFilterGroups));
        } catch (e) {
            parsedFilterGroups = [];
        }
        Object.entries(parsedFilterGroups).forEach(([_, fonctionnelGroup]) => {
            const filter = fonctionnelGroup.filter ? fonctionnelGroup.filter : '';
            const naming = fonctionnelGroup.naming ? fonctionnelGroup.naming : '';
            const quota = fonctionnelGroup.quota ? fonctionnelGroup.quota : '';
            const uaiNumber = fonctionnelGroup.uaiNumber ? fonctionnelGroup.uaiNumber : '';
            addFilterGroupLine(filter, naming, quota, uaiNumber);
        });
    }
}

function filterGroupInteractions() {
    const filterGroupTbody = document.querySelector('#filterGroup > tbody');
    filterGroupTbody.addEventListener('click', (event) => {
        const button = event.target;
        const row = button.closest('tr');
        switch (button.className) {
            case 'moveUpFilterGroup':
                row?.previousElementSibling?.before(row);
                break;
            case 'moveDownFilterGroup':
                row?.nextElementSibling?.after(row);
                break;
            case 'removeFilterGroup':
                row?.remove();
                break;
        }
    });

    document.querySelector('#addFilterGroup').addEventListener('click', () => {
        addFilterGroupLine();
    });
}

function addFilterGroupLine(filter = '', naming = '', quota = '', uaiNumber = '') {
    const line = document.createElement('tr');
    line.innerHTML = `
        <td>
            <input
                value="${filter}"
                class="cas_import_map_groups_filter"
            />
        </td>
        <td>
            <input
                value="${naming}"
                class="cas_import_map_groups_naming"
            />
        </td>
        <td>
            <input
                value="${uaiNumber}"
                class="cas_import_map_groups_uai_number"
            />
        </td>
        <td>
            <input
                value="${quota}"
                class="cas_import_map_groups_quota"
            />
        </td>
        <td>
            <button
                type="button"
                title="Monter"
                class="moveUpFilterGroup"
                style="width: 34px;"
            >
                ↑
            </button>
            <button
                type="button"
                title="Descendre"
                class="moveDownFilterGroup"
                style="width: 34px;"
            >
                ↓
            </button>
            <button
                type="button"
                title="Supprimer"
                class="removeFilterGroup"
                style="width: 34px;"
            >
                ×
            </button>
        </td>
    `;
    document.querySelector('#filterGroup > tbody').append(line);
}

// NameUaiGroup

function importMapNameUaiGroup() {
    const importNameUaiGroups = document.querySelector('#cas_import_map_regex_name_uai').value;
    if (importNameUaiGroups.length > 0) {
        let parsedNameUaiGroups = null;
        try {
            parsedNameUaiGroups = JSON.parse(decodeHTMLEntities(importNameUaiGroups))
        } catch (e) {
            parsedNameUaiGroups = []
        }
        Object.entries(parsedNameUaiGroups).forEach(([_, group]) => {
            const nameUai = group.nameUai ? group.nameUai : '';
            const nameGroup = group.nameGroup ? group.nameGroup : '';
            const uaiGroup = group.uaiGroup ? group.uaiGroup : '';
            addNameUaiGroupLine(nameUai, nameGroup, uaiGroup);
        });
    }
}

function nameUaiGroupInteractions() {
    const nameUaiGroupTbody = document.querySelector('#nameUaiGroup > tbody');
    nameUaiGroupTbody.addEventListener('click', (event) => {
        const button = event.target;
        const row = button.closest('tr');
        switch (button.className) {
            case 'moveUpNameUaiGroup':
                row?.previousElementSibling?.before(row);
                break;
            case 'moveDownNameUaiGroup':
                row?.nextElementSibling?.after(row);
                break;
            case 'removeNameUaiGroup':
                row?.remove();
                break;
        }
    });

    document.querySelector('#addNameUaiGroup').addEventListener('click', () => {
        addNameUaiGroupLine();
    });
}

function addNameUaiGroupLine(nameUai = '', nameGroup = '', uaiGroup = '') {
    const line = document.createElement('tr');
    line.innerHTML = `
        <td>
            <input
                value="${nameUai}"
                class="cas_import_regex_name_uai"
            />
        </td>
        <td>
            <input
                value="${nameGroup}"
                class="cas_import_regex_name_group"
            />
        </td>
        <td>
            <input
                value="${uaiGroup}"
                class="cas_import_regex_uai_group"
            />
        </td>
        <td>
            <button
                type="button"
                title="Monter"
                class="moveUpNameUaiGroup"
                style="width: 34px;"
            >
                ↑
            </button>
            <button
                type="button"
                title="Descendre"
                class="moveDownNameUaiGroup"
                style="width: 34px;"
            >
                ↓
            </button>
            <button
                type="button"
                title="Supprimer"
                class="removeNameUaiGroup"
                style="width: 34px;"
            >
                ×
            </button>
        </td>
    `;
    document.querySelector('#nameUaiGroup > tbody').append(line);
}

function computeHiddenFields() {
    let pegadogicGroups = {};
    document.querySelectorAll('.cas_import_map_groups_pedagogic').forEach((element, index) => {
        const value = element.value;
        if (value.length > 0) {
            pegadogicGroups[index] = {
                ...pegadogicGroups[index],
                'field': value
            }
        }
    })

    document.querySelectorAll('.cas_import_map_groups_pedagogic_filter').forEach((element, index) => {
        const value = element.value;
        if (value.length > 0) {
            pegadogicGroups[index] = {
                ...pegadogicGroups[index],
                'filter': value
            }
        }
    })
    document.querySelectorAll('.cas_import_map_groups_pedagogic_naming').forEach((element, index) => {
        const value = element.value;
        if (value.length > 0) {
            pegadogicGroups[index] = {
                ...pegadogicGroups[index],
                'naming': value
            }
        }
    })

    let filterGroups = {};
    document.querySelectorAll('.cas_import_map_groups_filter').forEach((element, index) => {
        const value = element.value;
        if (value.length > 0) {
            filterGroups[index] = {
                ...filterGroups[index],
                'filter': value
            }
        }
    })
    document.querySelectorAll('.cas_import_map_groups_naming').forEach((element, index) => {
        const value = element.value;
        if (value.length > 0) {
            filterGroups[index] = {
                ...filterGroups[index],
                'naming': value
            }
        }
    })
    document.querySelectorAll('.cas_import_map_groups_quota').forEach((element, index) => {
        const value = element.value;
        if (value.length > 0) {
            filterGroups[index] = {
                ...filterGroups[index],
                'quota': value
            }
        }
    })
    document.querySelectorAll('.cas_import_map_groups_uai_number').forEach((element, index) => {
        const value = element.value;
        if (value.length > 0) {
            filterGroups[index] = {
                ...filterGroups[index],
                'uaiNumber': value
            }
        }
    })

    let nameUaiGroup = {};
    document.querySelectorAll('.cas_import_regex_name_uai').forEach((element, index) => {
        const value = element.value;
        if (value.length > 0) {
            nameUaiGroup[index] = {
                ...nameUaiGroup[index],
                'nameUai': value
            }
        }
    })
    document.querySelectorAll('.cas_import_regex_name_group').forEach((element, index) => {
        const value = element.value;
        if (value.length > 0) {
            nameUaiGroup[index] = {
                ...nameUaiGroup[index],
                'nameGroup': value
            }
        }
    })
    document.querySelectorAll('.cas_import_regex_uai_group').forEach((element, index) => {
        const value = element.value;
        if (value.length > 0) {
            nameUaiGroup[index] = {
                ...nameUaiGroup[index],
                'uaiGroup': value
            }
        }
    })

    document.querySelector('#cas_import_map_groups_fonctionel').value = JSON.stringify(filterGroups);
    document.querySelector('#cas_import_map_groups_pedagogic').value = JSON.stringify(pegadogicGroups);
    document.querySelector('#cas_import_map_regex_name_uai').value = JSON.stringify(nameUaiGroup);
}
