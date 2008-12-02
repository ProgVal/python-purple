import purple
import ecore
import getpass
import sys

cbs = {}
acc_cbs = {}
conv_cbs = {}

def account_callback(name):
    print "---- account callback example: %s" % name

acc_cbs["notify_added"] = account_callback
acc_cbs["status_changed"] = account_callback
acc_cbs["request_add"] = account_callback
acc_cbs["request_authorize"] = account_callback
acc_cbs["close_account_request"] = account_callback

cbs["account"] = acc_cbs

def conv_callback(name):
    print "---- conversation callback example: %s" % name

conv_cbs["create_conversation"] = conv_callback
conv_cbs["destroy_conversation"] = conv_callback
conv_cbs["write_chat"] = conv_callback
conv_cbs["write_im"] = conv_callback
conv_cbs["write_conv"] = conv_callback
conv_cbs["chat_add_users"] = conv_callback
conv_cbs["chat_rename_user"] = conv_callback
conv_cbs["chat_remove_users"] = conv_callback
conv_cbs["chat_update_user"] = conv_callback
conv_cbs["present"] = conv_callback
conv_cbs["has_focus"] = conv_callback
conv_cbs["custom_smiley_add"] = conv_callback
conv_cbs["custom_smiley_write"] = conv_callback
conv_cbs["custom_smiley_close"] = conv_callback
conv_cbs["send_confirm"] = conv_callback

cbs["conversation"] = conv_cbs

class NullClient:
    def __init__(self):
        self.p = purple.Purple()
        self.account = None

    def execute(self):
        global cbs
        self.p.purple_init(cbs)

    def set_protocol(self, protocol):
        for i in self.p.get_protocols():
            if i[1] == protocol:
                print "-- NULLCLIENT --: Choosing %s as protocol" % protocol
                self.protocol = i[0]
                print "-- NULLCLIENT --: Protocol successfully chosen: %s" % i[0]
                return

    def new_account(self, username, protocol, password):
        self.account = purple.Account(username, protocol)
        self.account.set_password(password)
        self.account.set_enabled("carman-purple-python", True)
    def get_buddies(self):
        buddies = self.account.get_buddies_online()
        print buddies

def getuser():
    sys.stdout.write("GTalk account: ")
    username = sys.stdin.readline()
    return username[:-1]

def getpassword():
    return getpass.getpass()

if __name__ == '__main__':

    client = NullClient()
    client.execute()
    client.set_protocol("XMPP")
    username = getuser()
    password = getpassword()
    client.new_account(username, client.protocol, password)

    client.p.connect()
    ecore.timer_add(20, client.get_buddies)
    ecore.main_loop_begin()
