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
	<div>
		<Multiselect ref="multiselect"
			v-model="selected"
			class="sharing-input-etab"
			track-by="uai"
			label="name"
			:limit="3"
			:custom-label="searchLabel"
			:loading="loading"
			:options="etabs"
			:placeholder="inputPlaceholder"
			:multiple="true"
			:clear-on-select="true"
			open-direction="below"
			@input="change"
			@search-change="saveQuery">
			<template slot="option" slot-scope="etab">
				<div class="option__desc">
					<span class="option__name" v-html="highlight(etab.option.name)" />
					<span class="option__uai" v-html="highlight(etab.option.uai)" />
				</div>
			</template>
			<template slot="beforeList">
				<li>
					<div class="option__selectall">
						<span id="btnSelectAll"
							tabindex="0"
							role="button"
							@click="selectAll">{{ t('files_sharing', 'Select all') }}</span>
						<span id="btnSelectNone"
							tabindex="0"
							role="button"
							@click="deselectAll">{{ t('files_sharing', 'Select none') }}</span>
					</div>
				</li>
			</template>
			<template slot="afterList">
				<li>
					<div class="option__close">
						<span id="btnClose"
							tabindex="0"
							role="button"
							@click="toggle">{{ closeBtnTitle }}</span>
					</div>
				</li>
			</template>
			<template #noResult>
				{{ noResultText }}
			</template>
		</Multiselect>
	</div>
</template>

<script>
import { generateOcsUrl } from '@nextcloud/router'
import axios from '@nextcloud/axios'
import Multiselect from '@nextcloud/vue/dist/Components/Multiselect'

import MultiselectMixin from '../mixins/MultiselectMixin'

import Config from '../services/ConfigService'

export default {
	name: 'SharingInputEtab',

	components: {
		Multiselect,
	},

	mixins: [MultiselectMixin],

	data() {
		return {
			config: new Config(),
			loading: false,
			query: '',
			etabs: [],
			selected: [],
		}
	},

	computed: {
		inputPlaceholder() {
			const allowRemoteSharing = this.config.isRemoteShareAllowed

			// We can always search with email addresses for users too
			if (!allowRemoteSharing) {
				return t('files_sharing', 'Establishments')
			}

			return t('files_sharing', 'Establishments')
		},

		noResultText() {
			if (this.loading) {
				return t('files_sharing', 'Searching …')
			}
			return t('files_sharing', 'No elements found.')
		},

		closeBtnTitle() {
			return t('files_sharing', 'Close')
		},
		selectallBtnTitle() {
			if (this.selected.length === this.etabs.length) {
				return t('files_sharing', 'Unselect all')
			} else {
				return t('files_sharing', 'Select all')
			}
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
				request = await axios.get(generateOcsUrl('apps/files_sharing/api/v1', 2) + 'recia_list_etabs', {
					params: {
						format: 'json',
					},
				})
			} catch (error) {
				console.error('Error fetching etabs', error)
				return
			}

			this.etabs = request.data.ocs.data.data

			this.selected = this.etabs.filter(etab => etab.selected)
			this.selected.length >= 1 && this.change()

			this.loading = false
		},

		change() {
			this.isOpen && this.toggle()
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

		saveQuery(searchQuery) {
			this.query = searchQuery.trim()
		},

		highlight(text) {
			if (!this.query.length) return text
			return text.replace(new RegExp(this.query, 'gi'), function(match) {
				return '<strong>' + match + '</strong>'
			})
		},

		searchLabel(etab) {
			return `${etab.name} ${etab.uai}`
		},

		showLabel(etab) {
			return `${etab.name}`
		},

		selectAll() {
			this.selected = this.etabs
			this.toggle()
		},

		deselectAll() {
			this.selected = []
			this.toggle()
		},
	},
}
</script>

<style lang="scss">
.sharing-input-etab {
	width: 100%;
	margin: 10px 0;
	.option__desc{
		display: flex;
		flex-direction: column;
		justify-content: center;
		min-width: 0;
		.option__name, .option__uai{
			overflow: hidden;
			white-space: nowrap;
			text-overflow: ellipsis;
		}
		.option__name{
			color: var(--color-text-light);
		}
		.option__uai{
			font-size:smaller;
		}

	}
	.multiselect__option--highlight{
		&:not(.multiselect__option--selected){
			&:before{
				visibility:hidden !important;
			}
		}
		&:after{
			position: absolute;
			bottom: 5px;
			right:5px;
			content: 'Selectionner';
			opacity: 0.5;
		}
		&.multiselect__option--selected{
			&:after{
				content: 'Déselectionner';
			}
		}
	}
	.option__close, .option__selectall{
		display: flex;
		flex-wrap: wrap;
		width: 100%;
		font-weight: 700;
		text-align: center;
		padding: 8px;
		overflow: hidden;
		text-overflow: ellipsis;
		height: auto;
		min-height: 1em;
		background-color: transparent;
		span{
			flex:1;
			color: var(--color-text-lighter);
			&:hover{
				color: var(--color-text);
			}
		}
	}
}
</style>
