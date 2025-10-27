//
//  Post.swift
//  SSL_TLS_CERT_PINNING
//
//  Created by MD RASHID IQUBAL on 26/10/25.
//

import Foundation

struct Post: Codable {
    var name: String
}

struct GitHubAPIEndpoints: Codable {
    let currentUserURL: String?
    let currentUserAuthorizationsHTMLURL: String?
    let authorizationsURL: String?
    let codeSearchURL: String?
    let commitSearchURL: String?
    let emailsURL: String?
    let emojisURL: String?
    let eventsURL: String?
    let feedsURL: String?
    let followersURL: String?
    let followingURL: String?
    let gistsURL: String?
    let hubURL: String?
    let issueSearchURL: String?
    let issuesURL: String?
    let keysURL: String?
    let labelSearchURL: String?
    let notificationsURL: String?
    let organizationURL: String?
    let organizationRepositoriesURL: String?
    let organizationTeamsURL: String?
    let publicGistsURL: String?
    let rateLimitURL: String?
    let repositoryURL: String?
    let repositorySearchURL: String?
    let currentUserRepositoriesURL: String?
    let starredURL: String?
    let starredGistsURL: String?
    let topicSearchURL: String?
    let userURL: String?
    let userOrganizationsURL: String?
    let userRepositoriesURL: String?
    let userSearchURL: String?

    enum CodingKeys: String, CodingKey {
        case currentUserURL = "current_user_url"
        case currentUserAuthorizationsHTMLURL = "current_user_authorizations_html_url"
        case authorizationsURL = "authorizations_url"
        case codeSearchURL = "code_search_url"
        case commitSearchURL = "commit_search_url"
        case emailsURL = "emails_url"
        case emojisURL = "emojis_url"
        case eventsURL = "events_url"
        case feedsURL = "feeds_url"
        case followersURL = "followers_url"
        case followingURL = "following_url"
        case gistsURL = "gists_url"
        case hubURL = "hub_url"
        case issueSearchURL = "issue_search_url"
        case issuesURL = "issues_url"
        case keysURL = "keys_url"
        case labelSearchURL = "label_search_url"
        case notificationsURL = "notifications_url"
        case organizationURL = "organization_url"
        case organizationRepositoriesURL = "organization_repositories_url"
        case organizationTeamsURL = "organization_teams_url"
        case publicGistsURL = "public_gists_url"
        case rateLimitURL = "rate_limit_url"
        case repositoryURL = "repository_url"
        case repositorySearchURL = "repository_search_url"
        case currentUserRepositoriesURL = "current_user_repositories_url"
        case starredURL = "starred_url"
        case starredGistsURL = "starred_gists_url"
        case topicSearchURL = "topic_search_url"
        case userURL = "user_url"
        case userOrganizationsURL = "user_organizations_url"
        case userRepositoriesURL = "user_repositories_url"
        case userSearchURL = "user_search_url"
    }
}
