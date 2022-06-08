 /*
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
 */

#include "options.hpp"

#include <proton/connection.hpp>
#include <proton/connection_options.hpp>
#include <proton/container.hpp>
#include <proton/duration.hpp>
#include <proton/message.hpp>
#include <proton/message_id.hpp>
#include <proton/messaging_handler.hpp>
#include <proton/reconnect_options.hpp>
#include <proton/tracker.hpp>
#include <proton/types.hpp>
#include <proton/work_queue.hpp>

#include <iostream>
#include <map>
#include <unistd.h>


class simple_send : public proton::messaging_handler {
  private:
    std::string url;
    std::string user;
    std::string password;
    bool reconnect;
    proton::sender sender;
    int sent;
    int accepted;
    int rejected;
    int released;
    int total;
    proton::duration interval_1sec;

  public:
    simple_send(const std::string &s, const std::string &u, const std::string &p, bool r, int c) :
        url(s), user(u), password(p), reconnect(r), sent(0), accepted(0), rejected(0), released(0),
        total(c), interval_1sec(1 * proton::duration::SECOND) {}

    void on_container_start(proton::container &c) override {
        proton::connection_options co;
        if (!user.empty()) co.user(user);
        if (!password.empty()) co.password(password);
        co.sasl_allow_insecure_mechs(true);
        if (reconnect) co.reconnect(proton::reconnect_options());
        c.open_sender(url, co);
    }

    void on_connection_open(proton::connection& c) override {
        if (c.reconnected()) {
            sent = accepted;   // Re-send unaccepted messages after a reconnect
        }
    }

    void on_sender_open(proton::sender &s) override {
	    std::cout << "on_sender_open: ";
        sent = accepted;   // Re-send unaccepted messages after a reconnect
        if (s.credit()) {
            std::cout << "credit=true " << std::endl;
            s.work_queue().schedule(interval_1sec, [=] { send(s); });
        } else {
            std::cout << "credit=false " << std::endl;
        }
    }

    void on_sendable(proton::sender &s) override {
        std::cout << "on_sendable" << std::endl;
    }

    void send(proton::sender s) {
        if (s.active() && s.credit() && sent < total) {
            proton::message msg;
            std::map<std::string, int> m;
            m["sequence"] = sent + 1;

            msg.id(sent + 1);
            msg.body(m);

            s.send(msg);
            sent++;
            std::cout << "sent=" << sent << std::endl;
            s.work_queue().schedule(interval_1sec, [=] { send(s); });
        }
    }

    void on_sender_close(proton::sender &s) override {
        std::cout << "on_sender_close" << std::endl;
        s.work_queue().schedule(interval_1sec, [=] { reopen_sender(s); });
    }

    void reopen_sender(proton::sender s) {
        std::cout << "reopen_sender";
        if (accepted != total) {
            s.connection().open_sender(url);
            sent = accepted;   // Re-send unaccepted messages after a reconnect
            std::cout << " - reopening sender, sent reset to " << sent;
        }
        std::cout << std::endl;
    }

    void on_sender_error(proton::sender &s) override {
        std::cout << "on_sender_error: " << s.error().what() << std::endl;
    }

    void check_close_connection(proton::tracker &t) {
        std::cout << "accepted=" << accepted << " rejected=" << rejected << " released=" << released << std::endl;
        if (accepted + rejected + released == total) {
            if (rejected == 0 && released == 0) std::cout << "all messages accepted" << std::endl;
            else std::cout << "all messages accounted for" << std::endl;
            t.connection().close();
        }
    }

    void on_tracker_accept(proton::tracker &t) override {
        accepted++;
        std::cout << "accepted: ";
        check_close_connection(t);
    }

    void on_tracker_reject(proton::tracker &t) override {
        rejected++;
        std::cout << "rejected: ";
        check_close_connection(t);
    }

    void on_tracker_release(proton::tracker &t) override {
        released++;
        std::cout << "released: ";
        check_close_connection(t);
    }

    void on_transport_close(proton::transport &) override {
        sent = accepted;
    }
};

int main(int argc, char **argv) {
    std::string address;
    std::string user;
    std::string password;
    bool reconnect = false;
    int message_count = 100;
    example::options opts(argc, argv);

    opts.add_value(address, 'a', "address", "connect and send to URL", "URL");
    opts.add_value(user, 'u', "user", "authenticate as USER", "USER");
    opts.add_value(password, 'p', "password", "authenticate with PASSWORD", "PASSWORD");
    opts.add_flag(reconnect, 'r', "reconnect", "reconnect on connection failure");
    opts.add_value(message_count, 'm', "messages", "send COUNT messages", "COUNT");

    try {
        opts.parse();

        std::cout << "address: " << address << std::endl;
        std::cout << "user: " << user << std::endl;
        std::cout << "password: " << password << std::endl;
        std::cout << "reconnect: " << (reconnect?"T":"F") << std::endl;
        std::cout << "message_count: " << message_count << std::endl;

        simple_send send(address, user, password, reconnect, message_count);
        proton::container(send).run();

        return 0;
    } catch (const example::bad_option& e) {
        std::cout << opts << std::endl << e.what() << std::endl;
    } catch (const std::exception& e) {
        std::cerr << e.what() << std::endl;
    }

    return 1;
}
