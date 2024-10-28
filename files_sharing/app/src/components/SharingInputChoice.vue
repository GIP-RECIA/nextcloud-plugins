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
		<input id="search-type-etab"
			v-model="searchType"
			class="radio"
			type="radio"
			name="search-type"
			value="etab"
			@change="change">
		<label for="search-type-etab">
			{{ t('files_sharing', 'Your establishments') }}
		</label>
		<input id="search-type-all"
			v-model="searchType"
			class="radio"
			type="radio"
			name="search-type"
			value="all"
			@change="change">
		<label for="search-type-all">
			{{ t('files_sharing', 'All platform') }}
		</label>
	</div>
</template>

<script>

import Config from '../services/ConfigService.js'

export default {
	name: 'SharingInputChoice',

	data() {
		return {
			config: new Config(),
			loading: false,
			searchType: 'etab',
		}
	},

	methods: {
		change() {
			this.$emit('change', this.searchType)
		},
	},
}
</script>
