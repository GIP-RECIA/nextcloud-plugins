/**
 * @copyright Copyright (c) 2024 Quentin Guillemin
 *
 * @author Quentin Guillemin <quentin.guillemin@recia.fr>
 *
 * @license AGPL-3.0-or-later
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */
import HttpClient from '@nextcloud/axios'
import { generateOcsUrl } from '@nextcloud/router'

const CancelToken = HttpClient.CancelToken
let searchCancelSource = null

/**
 *
 * @param {string} searchType The type of search (etab or all)
 * @param {[]} selectedEtabs A list of selected
 * @param {string} query The search query
 * @param {string[]} hiddenPrincipals A list of principals to exclude from search results
 * @param {string[]} hiddenUrls A list of urls to exclude from search results
 * @return {Promise<object[]>}
 */
const findShareesFromFilesSharing = async (searchType = 'etabs', selectedEtabs = [], query, hiddenPrincipals, hiddenUrls) => {
	let results

	if (searchCancelSource) {
		searchCancelSource.cancel('Canceled')
	}

	searchCancelSource = CancelToken.source()

	if (searchType === 'etab' && selectedEtabs.length >= 1) {
		try {
			results = await HttpClient.get(generateOcsUrl('apps/files_sharing/api/v1/recia_search'), {
				cancelToken: searchCancelSource.token,
				params: {
					format: 'json',
					search: query,
					itemType: 'principals',
					etabs: selectedEtabs,
				},
			})
		} catch (error) {
			return []
		}
	} else {
		try {
			results = await HttpClient.get(generateOcsUrl('apps/files_sharing/api/v1/') + 'sharees', {
				cancelToken: searchCancelSource.token,
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
	}

	if (results.data.ocs.meta.status === 'failure') {
		return []
	}

	return [
		...results.data.ocs.data.users
			.filter((usr) => !hiddenPrincipals.includes(`principal:principals/users/${usr.value.shareWith}`))
			.map((usr) => {
				const user = usr.value.shareWith
				const uri = `principal:principals/users/${user}`

				return {
					displayName: usr.label,
					isCircle: false,
					isGroup: false,
					isNoUser: false,
					search: query,
					uri,
					user,
					email: JSON.parse(usr.shareWithDisplayNameUnique),
				}
			}),
		...results.data.ocs.data.groups
			.filter((group) => !hiddenPrincipals.includes(`principal:principals/groups/${group.label.replace(' ', '+')}`))
			.map((group) => {
				const user = group.label.replace(' ', '+')
				const uri = `principal:principals/groups/${user}`

				return {
					displayName: group.label,
					isCircle: false,
					isGroup: true,
					isNoUser: true,
					search: query,
					uri,
					user,
				}
			}),
	]
}

export { findShareesFromFilesSharing }
