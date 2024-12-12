<!--
  - @copyright Copyright (c) 2019 Georg Ehrke <oc.list@georgehrke.com>
  - @copyright Copyright (c) 2019 Jakob Röhrl <jakob.roehrl@web.de>
  -
  - @author Georg Ehrke <oc.list@georgehrke.com>
  - @author Jakob Röhrl <jakob.roehrl@web.de>
  - @author Richard Steinmetz <richard@steinmetz.cloud>
  -
  - @license AGPL-3.0-or-later
  -
  - This program is free software: you can redistribute it and/or modify
  - it under the terms of the GNU Affero General Public License as
  - published by the Free Software Foundation, either version 3 of the
  - License, or (at your option) any later version.
  -
  - This program is distributed in the hope that it will be useful,
  - but WITHOUT ANY WARRANTY; without even the implied warranty of
  - MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  - GNU Affero General Public License for more details.
  -
  - You should have received a copy of the GNU Affero General Public License
  - along with this program. If not, see <http://www.gnu.org/licenses/>.
  -
  -->

<template>
	<div class="sharing-search-recia">
		<label>{{ t('calendar', 'Search on :') }}</label>

		<div class="sharing-input-choice">
			<input id="search-type-etab"
				v-model="searchType"
				class="radio"
				type="radio"
				name="search-type"
				value="etab">
			<label for="search-type-etab">
				{{ t('calendar', 'Your establishments') }}
			</label>
			<input id="search-type-all"
				v-model="searchType"
				class="radio"
				type="radio"
				name="search-type"
				value="all">
			<label for="search-type-all">
				{{ t('calendar', 'All platform') }}
			</label>
		</div>

		<SharingInputEtab v-show="searchType === 'etab'" @change="updateSelectedEtabs" />

		<NcSelect :options="usersOrGroups"
			:searchable="true"
			:internal-search="false"
			:max-height="600"
			:placeholder="$t('calendar', 'Share with users or groups')"
			class="sharing-search-recia__select"
			:class="{ 'showContent': inputGiven, 'icon-loading': isLoading }"
			:user-select="true"
			:filter-by="filterResults"
			:clearable="false"
			open-direction="above"
			track-by="user"
			label="displayName"
			@search="findSharee"
			@option:selected="shareCalendar">
			<template #no-options>
				<span>{{ $t('calendar', 'No users or groups') }}</span>
			</template>
		</NcSelect>
	</div>
</template>

<script>
import { NcSelect } from '@nextcloud/vue'
import { principalPropertySearchByDisplaynameOrEmail } from '../../services/caldavService.js'
import { findShareesFromFilesSharing } from '../../services/filesSharingService.js'
import HttpClient from '@nextcloud/axios'
import debounce from 'debounce'
import { generateOcsUrl } from '@nextcloud/router'
import { urldecode } from '../../utils/url.js'

import SharingInputEtab from './SharingInputEtab.vue'

export default {
	name: 'SharingSearchRecia',
	components: {
		NcSelect,
		SharingInputEtab,
	},
	props: {
		calendar: {
			type: Object,
			required: true,
		},
	},
	data() {
		return {
			isLoading: false,
			inputGiven: false,
			usersOrGroups: [],
			searchType: 'etab',
			selectedEtabs: [],
		}
	},
	watch: {
		searchType() {
			this.usersOrGroups = []
		},
	},
	methods: {
		/**
		 * Share calendar
		 *
		 * @param {object} data destructuring object
		 * @param {string} data.user the userId
		 * @param {string} data.displayName the displayName
		 * @param {string} data.uri the sharing principalScheme uri
		 * @param {boolean} data.isGroup is this a group ?
		 * @param {boolean} data.isCircle is this a circle-group ?
		 */
		shareCalendar({ user, displayName, uri, isGroup, isCircle }) {
			this.$store.dispatch('shareCalendar', {
				calendar: this.calendar,
				user,
				displayName,
				uri,
				isGroup,
				isCircle,
			})
		},
		/**
		 * Function to filter results in NcSelect
		 *
		 * @param {object} option
		 * @param {string} label
		 * @param {string} search
		 */
		filterResults(option, label, search) {
			return true
		},
		/**
		 * Use the cdav client call to find matches to the query from the existing Users & Groups
		 *
		 * @param {string} query
		 */
		findSharee: debounce(async function(query) {
			const hiddenPrincipalSchemes = []
			const hiddenUrls = []
			this.calendar.shares.forEach((share) => {
				hiddenPrincipalSchemes.push(share.uri)
			})
			if (this.$store.getters.getCurrentUserPrincipal) {
				hiddenUrls.push(this.$store.getters.getCurrentUserPrincipal.url)
			}
			if (this.calendar.owner) {
				hiddenUrls.push(this.calendar.owner)
			}

			this.isLoading = true
			this.usersOrGroups = []

			if (query.length > 0) {
				try {
					this.usersOrGroups = await findShareesFromFilesSharing(
						this.searchType,
						this.selectedEtabs,
						query,
						hiddenPrincipalSchemes,
						hiddenUrls,
					)
				} catch (error) {
					console.debug(error)
				}

				this.isLoading = false
				this.inputGiven = true
			} else {
				this.inputGiven = false
				this.isLoading = false
			}
		}, 500),
		/**
		 *
		 * @param {string} query The search query
		 * @param {string[]} hiddenPrincipals A list of principals to exclude from search results
		 * @param {string[]} hiddenUrls A list of urls to exclude from search results
		 * @return {Promise<object[]>}
		 */
		async findShareesFromDav(query, hiddenPrincipals, hiddenUrls) {
			let results
			try {
				results = await principalPropertySearchByDisplaynameOrEmail(query)
			} catch (error) {
				return []
			}

			return results.reduce((list, result) => {
				if (['ROOM', 'RESOURCE'].includes(result.calendarUserType)) {
					return list
				}

				const isGroup = result.calendarUserType === 'GROUP'

				// TODO: Why do we have to decode those two values?
				const user = urldecode(result[isGroup ? 'groupId' : 'userId'])
				const decodedPrincipalScheme = urldecode(result.principalScheme)

				if (hiddenPrincipals.includes(decodedPrincipalScheme)) {
					return list
				}
				if (hiddenUrls.includes(result.url)) {
					return list
				}

				// Don't show resources and rooms
				if (!['GROUP', 'INDIVIDUAL'].includes(result.calendarUserType)) {
					return list
				}

				list.push({
					user,
					displayName: result.displayname,
					uri: decodedPrincipalScheme,
					isGroup,
					isCircle: false,
					isNoUser: isGroup,
					search: query,
				})
				return list
			}, [])
		},
		/**
		 *
		 * @param {string} query The search query
		 * @param {string[]} hiddenPrincipals A list of principals to exclude from search results
		 * @param {string[]} hiddenUrls A list of urls to exclude from search results
		 * @return {Promise<object[]>}
		 */
		async findShareesFromCircles(query, hiddenPrincipals, hiddenUrls) {
			let results
			try {
				results = await HttpClient.get(generateOcsUrl('apps/files_sharing/api/v1/') + 'sharees', {
					params: {
						format: 'json',
						search: query,
						perPage: 200,
						itemType: 'principals',
					},
				})
			} catch (error) {
				return []
			}

			if (results.data.ocs.meta.status === 'failure') {
				return []
			}

			let circles = []
			if (Array.isArray(results.data.ocs.data.circles)) {
				circles = circles.concat(results.data.ocs.data.circles)
			}
			if (Array.isArray(results.data.ocs.data.exact.circles)) {
				circles = circles.concat(results.data.ocs.data.exact.circles)
			}

			if (circles.length === 0) {
				return []
			}

			return circles.filter((circle) => {
				return !hiddenPrincipals.includes('principal:principals/circles/' + circle.value.shareWith)
			}).map(circle => ({
				user: circle.label,
				displayName: circle.label,
				icon: 'icon-circle',
				uri: 'principal:principals/circles/' + circle.value.shareWith,
				isGroup: false,
				isCircle: true,
				isNoUser: true,
				search: query,
			}))
		},

		updateSelectedEtabs(etabs) {
			this.selectedEtabs = etabs
		},
	},
}
</script>

<style lang="scss" scoped>
.sharing-search-recia {
	display: flex;
	flex-direction: column;
	margin-bottom: 4px;

	&__select {
		flex: 1 auto;
	}

	> .sharing-input-choice {
		margin-bottom: 4px;

		> label {
			margin-inline-end: 4px;

			&::before {
				margin-inline-end: 2px !important;
			}
		}
	}
}
</style>
