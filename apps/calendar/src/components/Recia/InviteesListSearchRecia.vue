<!--
  - @copyright Copyright (c) 2019 Georg Ehrke <oc.list@georgehrke.com>
  - @copyright Copyright (c) 2023 Jonas Heinrich <heinrich@synyx.net>
  -
  - @author Georg Ehrke <oc.list@georgehrke.com>
  - @author Richard Steinmetz <richard@steinmetz.cloud>
  - @author Jonas Heinrich <heinrich@synyx.net>
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
	<div class="invitees-list-search-recia ">
		<label>{{ t('calendar', 'Search on :') }}</label>

		<div class="sharing-input-choice">
			<input id="invitees-search-type-etab"
				v-model="searchType"
				class="radio"
				type="radio"
				name="invitees-search-type"
				value="etab">
			<label for="invitees-search-type-etab">
				{{ t('calendar', 'Your establishments') }}
			</label>
			<input id="invitees-search-type-all"
				v-model="searchType"
				class="radio"
				type="radio"
				name="invitees-search-type"
				value="all">
			<label for="invitees-search-type-all">
				{{ t('calendar', 'All platform') }}
			</label>
		</div>

		<SharingInputEtab v-show="searchType === 'etab'" @change="updateSelectedEtabs" />

		<NcSelect class="invitees-search__multiselect"
			:options="matches"
			:searchable="true"
			:max-height="600"
			:placeholder="placeholder"
			:class="{ 'showContent': inputGiven, 'icon-loading': isLoading }"
			:clearable="false"
			:label-outside="true"
			input-id="uid"
			label="dropdownName"
			@search="findAttendees"
			@option:selected="addAttendee">
			<template #option="option">
				<div class="invitees-search-list-item">
					<!-- We need to specify a unique key here for the avatar to be reactive. -->
					<Avatar v-if="option.isUser"
						:key="option.uid"
						:user="option.avatar"
						:display-name="option.dropdownName" />
					<Avatar v-else-if="option.type === 'circle'">
						<template #icon>
							<GoogleCirclesCommunitiesIcon :size="20" />
						</template>
					</Avatar>
					<Avatar v-if="!option.isUser && option.type !== 'circle'"
						:key="option.uid"
						:url="option.avatar"
						:display-name="option.commonName" />

					<div class="invitees-search-list-item__label">
						<div>
							{{ option.commonName }}
						</div>
						<div v-if="option.email !== option.commonName && option.type !== 'circle'">
							{{ option.email }}
						</div>
						<div v-if="option.type === 'circle'">
							{{ option.subtitle }}
						</div>
					</div>
				</div>
			</template>
		</NcSelect>
	</div>
</template>

<script>
import {
	NcAvatar as Avatar,
	NcSelect,
} from '@nextcloud/vue'
import { findShareesFromFilesSharing } from '../../services/filesSharingService.js'
import debounce from 'debounce'
import { randomId } from '../../utils/randomId.js'
import GoogleCirclesCommunitiesIcon from 'vue-material-design-icons/GoogleCirclesCommunities.vue'
import { showInfo } from '@nextcloud/dialogs'

import SharingInputEtab from './SharingInputEtab.vue'

export default {
	name: 'InviteesListSearchRecia',
	components: {
		Avatar,
		NcSelect,
		GoogleCirclesCommunitiesIcon,
		SharingInputEtab,
	},
	props: {
		alreadyInvitedEmails: {
			type: Array,
			required: true,
		},
		organizer: {
			type: Object,
			required: false,
		},
	},
	data() {
		return {
			isLoading: false,
			inputGiven: false,
			matches: [],
			searchType: 'etab',
			selectedEtabs: [],
		}
	},
	computed: {
		placeholder() {
			return this.$t('calendar', 'Search for emails, users, contacts or groups')
		},
		noResult() {
			return this.$t('calendar', 'No match found')
		},
	},
	watch: {
		searchType() {
			this.usersOrGroups = []
		},
	},
	methods: {
		findAttendees: debounce(async function(query) {
			this.isLoading = true
			const matches = []

			if (query.length > 0) {
				const promises = [
					this.findAttendeesFromFilesSharing(query),
				]

				const [
					filesSharingResults,
				] = await Promise.all(promises)
				matches.push(...filesSharingResults)

				// Source of the Regex: https://stackoverflow.com/a/46181
				// eslint-disable-next-line
				const emailRegex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
				if (emailRegex.test(query)) {
					const alreadyInList = matches.find((attendee) => attendee.email.toLowerCase() === query.toLowerCase())
					if (!alreadyInList) {
						matches.unshift({
							calendarUserType: 'INDIVIDUAL',
							commonName: query,
							email: query,
							isUser: false,
							avatar: null,
							language: null,
							timezoneId: null,
							hasMultipleEMails: false,
							dropdownName: query,
						})
					}
				}

				// Generate a unique id for every result to make the avatar components reactive
				for (const match of matches) {
					match.uid = randomId()
				}

				this.isLoading = false
				this.inputGiven = true
			} else {
				this.inputGiven = false
				this.isLoading = false
			}

			this.matches = matches
		}, 500),
		addAttendee(selectedValue) {

			if (selectedValue.type === 'circle') {
				showInfo(this.$t('calendar', 'Note that members of circles get invited but are not synced yet.'))
				this.resolveCircleMembers(selectedValue.id, selectedValue.email)
			}
			this.$emit('add-attendee', selectedValue)
		},
		async findAttendeesFromFilesSharing(query) {
			let results
			try {
				results = await findShareesFromFilesSharing(
					this.searchType,
					this.selectedEtabs,
					query,
					[],
				)
			} catch (error) {
				console.debug(error)
				return []
			}

			return results.map((userOrGroup) => {
				return {
					calendarUserType: userOrGroup.isGroup ? 'GROUP' : 'INDIVIDUAL',
					commonName: userOrGroup.displayName,
					email: userOrGroup.email,
					isUser: !userOrGroup.isGroup,
					avatar: userOrGroup.user,
					dropdownName: userOrGroup.email ? [userOrGroup.displayName, userOrGroup.email].join(' ') : userOrGroup.displayName,
				}
			})
		},
		updateSelectedEtabs(etabs) {
			this.selectedEtabs = etabs
		},
	},
}
</script>

<style lang="scss">
.invitees-list-search-recia {
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
