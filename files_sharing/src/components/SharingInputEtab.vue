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
			track-by="siren"
			label="name"
			:loading="loading"
			:options="etabs"
			:placeholder="inputPlaceholder"
			:multiple="true"
			open-direction="below"
			@input="change">
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

import Config from '../services/ConfigService'

export default {
	name: 'SharingInputEtab',

	components: {
		Multiselect,
	},

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
			console.info('establishments', this.etabs)
		},

		change() {
			this.$emit('change', this.selected.map(etab => etab.siren))
		},
	},
}
</script>

<style lang="scss">
.sharing-input-etab {
	width: 100%;
	margin: 10px 0;
}
</style>
