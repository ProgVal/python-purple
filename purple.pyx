#
#  Copyright (c) 2008 INdT - Instituto Nokia de Tecnologia
#
#  This file is part of python-purple.
#
#  python-purple is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  python-purple is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

cimport purple

cdef extern from "c_purple.h":
    glib.guint glib_input_add(glib.gint fd, eventloop.PurpleInputCondition condition, eventloop.PurpleInputFunction function, glib.gpointer data)

import signal

cdef glib.GHashTable *c_ui_info

c_ui_info = NULL

cdef char *c_ui_name
cdef char *c_ui_version
cdef char *c_ui_website
cdef char *c_ui_dev_website

cdef account.PurpleAccountUiOps c_account_ui_ops
cdef blist.PurpleBlistUiOps c_blist_ui_ops
cdef connection.PurpleConnectionUiOps c_conn_ui_ops
cdef conversation.PurpleConversationUiOps c_conv_ui_ops
cdef core.PurpleCoreUiOps c_core_ui_ops
cdef eventloop.PurpleEventLoopUiOps c_eventloop_ui_ops
#cdef ft.PurpleXferUiOps c_ft_ui_ops
cdef notify.PurpleNotifyUiOps c_notify_ui_ops
#cdef privacy.PurplePrivacyUiOps c_privacy_ui_ops
cdef request.PurpleRequestUiOps c_request_ui_ops
#cdef roomlist.PurpleRoomlistUiOps c_rlist_ui_ops

include "account_cbs.pxd"
include "blist_cbs.pxd"
include "connection_cbs.pxd"
include "conversation_cbs.pxd"
#include "xfer_cbs.pxd"
include "notify_cbs.pxd"
#include "privacy_cbs.pxd"
include "request_cbs.pxd"
#include "roomlist_cbs.pxd"
include "signal_cbs.pxd"

include "util.pxd"

cdef class Purple:
    '''Purple class.

    @param ui_name ID of the UI using the purple.
        This should be a unique ID, registered with the purple team.
    @param ui_version UI version.
    @param ui_website UI website.
    @param ui_dev_website UI development website.
    @param debug_enabled True to enable debug messages.
    @param default_path Custom settings directory
    '''


    def __init__(self, ui_name, ui_version, ui_website, ui_dev_website, \
            debug_enabled=None, default_path=None):

        global c_ui_name
        global c_ui_version
        global c_ui_website
        global c_ui_dev_website

        c_ui_name = ui_name
        c_ui_version = ui_version
        c_ui_website = ui_website
        c_ui_dev_website = ui_dev_website

        if debug_enabled:
            debug.purple_debug_set_enabled(debug_enabled)

        if default_path:
            util.purple_util_set_user_dir(default_path)

        # libpurple's built-in DNS resolution forks processes to perform
        # blocking lookups without blocking the main process.  It does not
        # handle SIGCHLD itself, so if the UI does not you quickly get an army
        # of zombie subprocesses marching around.
        signal.signal(signal.SIGCHLD, signal.SIG_IGN)

    def destroy(self):
        core.purple_core_quit()

    def __get_ui_name(self):
        '''Returns the UI name.

        @return UI name.
        '''

        global c_ui_name
        return str(c_ui_name)
    ui_name = property(__get_ui_name)

    cdef void __core_ui_ops_ui_prefs_init(self):
        debug.purple_debug_info("core_ui_ops", "%s", "ui_prefs_init")
        prefs.purple_prefs_load()

        prefs.purple_prefs_add_none("/carman")

    cdef void __core_ui_ops_debug_init(self):
        debug.purple_debug_info("core_ui_ops", "%s", "debug_ui_init")
        pass

    cdef void __core_ui_ops_ui_init(self):
        debug.purple_debug_info("core_ui_ops", "%s", "ui_init")

        account.purple_accounts_set_ui_ops(&c_account_ui_ops)
        connection.purple_connections_set_ui_ops(&c_conn_ui_ops)
        blist.purple_blist_set_ui_ops(&c_blist_ui_ops)
        conversation.purple_conversations_set_ui_ops(&c_conv_ui_ops)
        notify.purple_notify_set_ui_ops(&c_notify_ui_ops)
        #privacy.purple_privacy_set_ui_ops(&c_privacy_ui_ops)
        request.purple_request_set_ui_ops(&c_request_ui_ops)
        #ft.purple_xfers_set_ui_ops(&c_ft_ui_ops)
        #roomlist.purple_roomlist_set_ui_ops(&c_rlist_ui_ops)

    cdef void __core_ui_ops_quit(self):
        debug.purple_debug_info("core_ui_ops", "%s", "quit")

        account.purple_accounts_set_ui_ops(NULL)
        connection.purple_connections_set_ui_ops(NULL)
        blist.purple_blist_set_ui_ops(NULL)
        conversation.purple_conversations_set_ui_ops(NULL)
        notify.purple_notify_set_ui_ops(NULL)
        #privacy.purple_privacy_set_ui_ops(NULL)
        request.purple_request_set_ui_ops(NULL)
        #ft.purple_xfers_set_ui_ops(NULL)
        #roomlist.purple_roomlist_set_ui_ops(NULL)

        if self.c_ui_info:
            glib.g_hash_table_destroy(<glib.GHashTable *> self.c_ui_info)

    cdef glib.GHashTable *__core_ui_ops_get_ui_info(self):
        global c_ui_info
        global c_ui_name
        global c_ui_version
        global c_ui_website
        global c_ui_dev_website

        if c_ui_info == NULL:
            c_ui_info = glib.g_hash_table_new(glib.g_str_hash, \
                    glib.g_str_equal)

            glib.g_hash_table_insert(c_ui_info, "name", c_ui_name)
            glib.g_hash_table_insert(c_ui_info, "version", c_ui_version)
            glib.g_hash_table_insert(c_ui_info, "website", c_ui_website)
            glib.g_hash_table_insert(c_ui_info, "dev_website", c_ui_dev_website)
        return c_ui_info

    def purple_init(self):
        '''Initializes the purple.

        This will setup preferences for all the core subsystems.
        '''

        global c_ui_name

        c_account_ui_ops.notify_added = notify_added
        c_account_ui_ops.status_changed = status_changed
        c_account_ui_ops.request_add = request_add
        c_account_ui_ops.request_authorize = request_authorize
        c_account_ui_ops.close_account_request = close_account_request

        c_blist_ui_ops.new_list = new_list
        c_blist_ui_ops.new_node = new_node
        c_blist_ui_ops.show = show
        c_blist_ui_ops.update = update
        c_blist_ui_ops.remove = remove
        c_blist_ui_ops.destroy = destroy
        c_blist_ui_ops.set_visible = set_visible
        c_blist_ui_ops.request_add_buddy = request_add_buddy
        c_blist_ui_ops.request_add_chat = request_add_chat
        c_blist_ui_ops.request_add_group = request_add_group

        c_conn_ui_ops.connect_progress = connect_progress
        c_conn_ui_ops.connected = connected
        c_conn_ui_ops.disconnected = disconnected
        c_conn_ui_ops.notice = notice
        c_conn_ui_ops.report_disconnect = report_disconnect
        c_conn_ui_ops.network_connected = network_connected
        c_conn_ui_ops.network_disconnected = network_disconnected
        c_conn_ui_ops.report_disconnect_reason = report_disconnect_reason

        c_conv_ui_ops.create_conversation = create_conversation
        c_conv_ui_ops.destroy_conversation = destroy_conversation
        c_conv_ui_ops.write_chat = write_chat
        c_conv_ui_ops.write_im = write_im
        c_conv_ui_ops.write_conv = write_conv
        c_conv_ui_ops.chat_add_users = chat_add_users
        c_conv_ui_ops.chat_rename_user = chat_rename_user
        c_conv_ui_ops.chat_remove_users = chat_remove_users
        c_conv_ui_ops.chat_update_user = chat_update_user
        c_conv_ui_ops.present = present
        c_conv_ui_ops.has_focus = has_focus
        c_conv_ui_ops.custom_smiley_add = custom_smiley_add
        c_conv_ui_ops.custom_smiley_write = custom_smiley_write
        c_conv_ui_ops.custom_smiley_close = custom_smiley_close
        c_conv_ui_ops.send_confirm = send_confirm

        c_notify_ui_ops.notify_message = notify_message
        c_notify_ui_ops.notify_email = notify_email
        c_notify_ui_ops.notify_emails = notify_emails
        c_notify_ui_ops.notify_formatted = notify_formatted
        c_notify_ui_ops.notify_searchresults = notify_searchresults
        c_notify_ui_ops.notify_searchresults_new_rows = notify_searchresults_new_rows
        c_notify_ui_ops.notify_userinfo = notify_userinfo
        c_notify_ui_ops.notify_uri = notify_uri
        c_notify_ui_ops.close_notify = close_notify

        c_request_ui_ops.request_input = request_input
        c_request_ui_ops.request_choice = request_choice
        c_request_ui_ops.request_action = request_action
        c_request_ui_ops.request_fields = request_fields
        c_request_ui_ops.request_file = request_file
        c_request_ui_ops.close_request = close_request
        c_request_ui_ops.request_folder = request_folder

        c_core_ui_ops.ui_prefs_init = <void (*)()> self.__core_ui_ops_ui_prefs_init
        c_core_ui_ops.debug_ui_init = <void (*)()> self.__core_ui_ops_debug_init
        c_core_ui_ops.ui_init = <void (*)()> self.__core_ui_ops_ui_init
        c_core_ui_ops.quit = <void (*)()> self.__core_ui_ops_quit
        c_core_ui_ops.get_ui_info = <glib.GHashTable* (*)()> self.__core_ui_ops_get_ui_info

        c_eventloop_ui_ops.timeout_add = glib.g_timeout_add
        c_eventloop_ui_ops.timeout_remove = glib.g_source_remove
        c_eventloop_ui_ops.input_add = glib_input_add
        c_eventloop_ui_ops.input_remove = glib.g_source_remove
        c_eventloop_ui_ops.input_get_error = NULL
        c_eventloop_ui_ops.timeout_add_seconds = NULL

        core.purple_core_set_ui_ops(&c_core_ui_ops)
        eventloop.purple_eventloop_set_ui_ops(&c_eventloop_ui_ops)

        # initialize purple core
        ret = core.purple_core_init(c_ui_name)
        if ret is False:
            debug.purple_debug_fatal("main", "%s", "libpurple " \
                                       "initialization failed.\n")
            return False

        # check if there is another instance of libpurple running
        if core.purple_core_ensure_single_instance() == False:
            debug.purple_debug_fatal("main", "%s", "Another instance of " \
                                      "libpurple is already running.\n")
            core.purple_core_quit()
            return False

        # create and load the buddy list
        blist.purple_set_blist(blist.purple_blist_new())
        blist.purple_blist_load()

        # load pounces
        pounce.purple_pounces_load()

        return ret

    def add_callback(self, type, name, callback):
        '''Adds a callback with given name inside callback's type.

        @param type     Callback type (e.g. "account")
        @param name     Callback name (e.g. "notify-added")
        @param callback Callback to be called
        '''

        global account_cbs
        global blist_cbs
        global connection_cbs
        global conversation_cbs
        global notify_cbs
        global request_cbs

        { "account": account_cbs,
          "blist": blist_cbs,
          "connection": connection_cbs,
          "conversation": conversation_cbs,
          "notify": notify_cbs,
          "request": request_cbs }[type][name] = callback

    def signal_connect(self, name=None, cb=None):
        '''Connects a signal handler to a callback for a particular object.
        Take care not to register a handler function twice. Purple will
        not correct any mistakes for you in this area.

        @param name Name of the signal to connect.
        @param cb Callback function.
        '''

        cdef int handle
        cdef plugin.PurplePlugin *jabber

        if name is None:
            return

        jabber = prpl.purple_find_prpl("prpl-jabber")
        if jabber == NULL:
            return

        global signal_cbs
        signal_cbs[name] = cb

        if name == "signed-on":
            signals.purple_signal_connect(
                    connection.purple_connections_get_handle(),
                    "signed-on", &handle,
                    <signals.PurpleCallback> signal_signed_on_cb, NULL)
        elif name == "signed-off":
            signals.purple_signal_connect(
                    connection.purple_connections_get_handle(),
                    "signed-off", &handle,
                    <signals.PurpleCallback> signal_signed_off_cb, NULL)
        elif name == "connection-error":
            signals.purple_signal_connect(
                    connection.purple_connections_get_handle(),
                    "connection-error", &handle,
                    <signals.PurpleCallback> signal_connection_error_cb, NULL)
        elif name == "buddy-signed-on":
            signals.purple_signal_connect(
                    blist.purple_blist_get_handle(),
                    "buddy-signed-on", &handle,
                    <signals.PurpleCallback> signal_buddy_signed_on_cb, NULL)
        elif name == "buddy-signed-off":
            signals.purple_signal_connect(
                    blist.purple_blist_get_handle(),
                    "buddy-signed-off", &handle,
                    <signals.PurpleCallback> signal_buddy_signed_off_cb, NULL)
        elif name == "receiving-im-msg":
            signals.purple_signal_connect(
                    conversation.purple_conversations_get_handle(),
                    "receiving-im-msg", &handle,
                    <signals.PurpleCallback> signal_receiving_im_msg_cb, NULL)
        elif name == "jabber-receiving-xmlnode":
            signals.purple_signal_connect(
                    jabber, "jabber-receiving-xmlnode", &handle,
                    <signals.PurpleCallback> jabber_receiving_xmlnode_cb, NULL)

    def accounts_get_all(self):
        '''Returns a list of all accounts.

        @return A list of all accounts.
        '''

        cdef glib.GList *iter
        cdef account.PurpleAccount *acc
        cdef char *username
        cdef char *protocol_id

        iter = account.purple_accounts_get_all()
        account_list = []

        while iter:
            acc = <account.PurpleAccount *> iter.data

            if <account.PurpleAccount *>acc:
                username = <char *> account.purple_account_get_username(acc)
                protocol_id = <char *> account.purple_account_get_protocol_id(acc)

                if username != NULL and protocol_id != NULL:
                    account_list.append(Account(username, \
                            Protocol(protocol_id), self))
            iter = iter.next

        return account_list

    def accounts_get_all_active(self):
        '''Returns a list of all enabled accounts.

        @return A list of all enabled accounts.
        '''

        cdef glib.GList *iter
        cdef account.PurpleAccount *acc
        cdef char *username
        cdef char *protocol_id

        #FIXME: The list is owned by the caller, and must be g_list_free()d
        #       to avoid leaking the nodes.

        iter = account.purple_accounts_get_all_active()
        account_list = []

        while iter:
            acc = <account.PurpleAccount *> iter.data

            if <account.PurpleAccount *>acc:
                username = <char *> account.purple_account_get_username(acc)
                protocol_id = <char *> account.purple_account_get_protocol_id(acc)

                if username != NULL and protocol_id != NULL:
                    account_list.append(Account(username, \
                            Protocol(protocol_id), self))
            iter = iter.next

        return account_list

    def iterate_main_loop(self):
        glib.g_main_context_iteration(NULL, False)
        return True

    def protocols_get_all(self):
        '''Returns a list of all protocols.

        @return A list of all protocols.
        '''

        cdef glib.GList *iter
        cdef plugin.PurplePlugin *pp

        iter = plugin.purple_plugins_get_protocols()
        protocol_list = []
        while iter:
            pp = <plugin.PurplePlugin*> iter.data
            if <bint> pp.info and <bint> pp.info.name:
                protocol_list.append(Protocol(pp.info.id))
            iter = iter.next
        return protocol_list

    def call_action(self, i):
        __call_action(i)

include "protocol.pyx"
#include "plugin.pyx"
include "proxy.pyx"
include "account.pyx"
include "conversation.pyx"
