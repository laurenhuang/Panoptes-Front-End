React = require 'react'
{Link} = require 'react-router'
auth = require '../api/auth'

module.exports = React.createClass
  displayName: 'AccountBar'

  render: ->
    <div className="account-bar">
      <img src={@props.user.avatar} className="account-bar-avatar" />{' '}
      <strong><Link to="user-profile" params={name: @props.user.display_name}>{@props.user.display_name}</Link></strong>{' '}
      <button type="button" className="pill" onClick={@handleSignOutClick}>Sign out</button>{' '}
      <Link to="settings" className="pill">Settings</Link>
    </div>

  handleSignOutClick: ->
    auth.signOut()
