/* eslint-disable vue/no-v-html */
<!--
  - @copyright Copyright (c) 2021 Recia
  -
  - @author Grégory Brousse <pro@gregory-brousse.fr>
  -
  - @license GNU AGPL version 3 or any later version
  -
  - This program is free software: you can redistribute it and/or modify
  - it under the terms of the GNU Affero General Public License as
  - published by the Free Software Foundation, either version 3 of the
  - License, or (at your option) any later version.
  -
  - This program is distributed in the hope that it will be useful,
  - but WITHOUT ANY WARRANTY; without even the implied warranty of
  - MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  - GNU Affero General Public License for more details.
  -
  - You should have received a copy of the GNU Affero General Public License
  - along with this program. If not, see <http://www.gnu.org/licenses/>.
  -
  -->

<template>
	<NcSelect v-model="selected"
		:loading="loading"
		:options="etabs"
		:placeholder="t('files_sharing', 'Establishments')"
		:close-on-select="false"
		multiple
		deselect-from-dropdown
		class="sharing-input-etab"
		@input="change"
		@search="saveQuery">
		<template #list-header>
			<li>
				<div class="option__selectall">
					<NcButton type="tertiary"
						size="small"
						:aria-label="t('files_sharing', 'Select all')"
						@click="selectAll">
						{{ t('files_sharing', 'Select all') }}
					</NcButton>
					<NcButton type="tertiary"
						size="small"
						:aria-label="t('files_sharing', 'Select none')"
						@click="deselectAll">
						{{ t('files_sharing', 'Select none') }}
					</NcButton>
				</div>
			</li>
		</template>
		<template #no-options>
			{{ noResultText }}
		</template>
		<template #option="{ name, uai }">
			<div class="option__container">
				<NcIconSvgWrapper class="option__icon" :path="mdiCheck" inline />
				<div class="option__desc">
					<NcHighlight class="option__name" :text="name" :search="query" />
					<NcHighlight class="option__uai" :text="uai" :search="query" />
				</div>
			</div>
		</template>
		<template #selected-option-container="{ option }">
			<div class="vs__selected">
				{{ option.name }}
			</div>
		</template>
	</NcSelect>
</template>

<script>
import { mdiCheck } from '@mdi/js'
import { generateOcsUrl } from '@nextcloud/router'
import axios from '@nextcloud/axios'
import NcButton from '@nextcloud/vue/dist/Components/NcButton.js'
import NcHighlight from '@nextcloud/vue/dist/Components/NcHighlight.js'
import NcIconSvgWrapper from '@nextcloud/vue/dist/Components/NcIconSvgWrapper.js'
import NcSelect from '@nextcloud/vue/dist/Components/NcSelect.js'

import Config from '../services/ConfigService.js'

export default {
	name: 'SharingInputEtab',

	components: {
		NcButton,
		NcHighlight,
		NcIconSvgWrapper,
		NcSelect,
	},

	data() {
		return {
			config: new Config(),
			loading: false,
			query: '',
			etabs: [],
			selected: [],
			mdiCheck,
		}
	},

	computed: {
		noResultText() {
			if (this.loading) {
				return t('files_sharing', 'Searching …')
			}
			return t('files_sharing', 'No elements found.')
		},
	},

	mounted() {
		this.getEtabs()
	},

	methods: {
		/**
		 * Récupère les établissements
		 */
		async getEtabs() {
			this.loading = true

			let request = null
			try {
				request = await axios.get(generateOcsUrl('apps/files_sharing/api/v1/recia_list_etabs'), {
					params: {
						format: 'json',
					},
				})
			} catch (error) {
				console.error('Error fetching etabs', error)
				return
			}

			this.etabs = request.data.ocs.data.data.map(etab => {
				const label = `${etab.name} ${etab.uai ?? ''}`

				return { ...etab, label }
			})

			this.selected = this.etabs.filter(etab => etab.selected)
			this.selected.length >= 1 && this.change()

			this.loading = false
		},

		change() {
			this.isChanging()
		},

		saveQuery(searchQuery) {
			this.query = searchQuery.trim()
		},

		selectAll() {
			this.selected = this.etabs
			this.isChanging()
		},

		deselectAll() {
			this.selected = []
			this.isChanging()
		},

		isChanging() {
			const sirenList = this.selected.map(etab => etab.siren)
			this.$emit('change', sirenList)
			this.etabs.sort((etab1, etab2) => {
				etab1.selected = sirenList.includes(etab1.siren)
				etab2.selected = sirenList.includes(etab2.siren)
				if (etab1.selected && etab2.selected) {
					return etab1.name.localeCompare(etab2.name)
				} else {
					if (etab1.selected || etab2.selected) {
						return etab1.selected ? -1 : +1
					} else {
						return etab1.name.localeCompare(etab2.name)
					}
				}
			})
		},
	},
}
</script>

<style lang="scss">
.sharing-input-etab {
	width: 100%;

	.vs__selected {
		padding-inline: 12px !important;
	}
}

.vs__dropdown-menu {
	.option__selectall{
		display: flex;
		padding-bottom: 6px;
		column-gap: 4px;

		button {
			flex: 1;
		}
	}

	.vs__dropdown-option {
		.option__container {
			position: relative;
			display: flex;
			cursor: pointer;

			.option__icon {
				margin-right: 8px;
				visibility: hidden;
			}

			.option__desc {
				display: flex;
				flex-direction: column;
				justify-content: center;
				min-width: 0;

				.option__name,
				.option__uai {
					overflow: hidden;
					white-space: nowrap;
					text-overflow: ellipsis;
				}

				.option__uai {
					font-size: smaller;
					opacity: 0.5;
				}
			}
		}

		&.vs__dropdown-option--selected {
			--vs-dropdown-option--deselect-bg: var(--vs-dropdown-option--active-bg);
			--vs-dropdown-option--deselect-color: var(--vs-dropdown-option--active-color);

			.option__icon {
				visibility: unset !important;
			}
		}

		// &.vs__dropdown-option--highlight {
		// 	.option__container:after {
		// 		position: absolute;
		// 		bottom: 0;
		// 		right: 0;
		// 		opacity: 0.5;
		// 		content: 'Selectionner';
		// 	}

		// 	&.vs__dropdown-option--selected {
		// 		.option__container:after {
		// 			content: 'Déselectionner';
		// 		}
		// 	}
		// }
	}
}
</style>
