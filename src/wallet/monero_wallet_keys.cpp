/**
 * Copyright (c) 2017-2019 woodser
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * Parts of this file are originally copyright (c) 2014-2019, The Monero Project
 *
 * Redistribution and use in source and binary forms, with or without modification, are
 * permitted provided that the following conditions are met:
 *
 * All rights reserved.
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of
 *    conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list
 *    of conditions and the following disclaimer in the documentation and/or other
 *    materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be
 *    used to endorse or promote products derived from this software without specific
 *    prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Parts of this file are originally copyright (c) 2012-2013 The Cryptonote developers
 */

#include "monero_wallet_keys.h"

#include "utils/monero_utils.h"
#include <chrono>
#include <stdio.h>
#include <iostream>
#include "mnemonics/electrum-words.h"
#include "mnemonics/english.h"
#include "cryptonote_basic.h"
#include "cryptonote_basic/account.h"
#include "string_tools.h"
#include "device/device.hpp"

using namespace std;
using namespace epee;
using namespace tools;
using namespace crypto;

/**
 * Public library interface.
 */
namespace monero {

  // ---------------------------- WALLET MANAGEMENT ---------------------------

  monero_wallet_keys* monero_wallet_keys::create_wallet_random(const monero_network_type network_type, const string& language) {
    cout << "monero_wallet_keys::create_wallet_random(...)" << endl;
    throw runtime_error("create_wallet_random(...) not implemented");
  }

  monero_wallet_keys* monero_wallet_keys::create_wallet_from_mnemonic(const monero_network_type network_type, const string& mnemonic) {
    cout << "monero_wallet_keys::create_wallet_from_mnemonic()" << endl;

    // validate mnemonic and get recovery key and language
    crypto::secret_key recovery_key;
    string language;
    bool is_valid = crypto::ElectrumWords::words_to_bytes(mnemonic, recovery_key, language);
    if (!is_valid) throw runtime_error("Invalid mnemonic");
    if (language == crypto::ElectrumWords::old_language_name) language = Language::English().get_language_name();

    // initialize keys
    cryptonote::account_base account{};
    account.generate(recovery_key, true, false);
    const cryptonote::account_keys& keys = account.get_keys();

    // initialize wallet
    monero_wallet_keys* wallet = new monero_wallet_keys();
    wallet->m_seed = epee::string_tools::pod_to_hex(recovery_key);
    wallet->m_mnemonic = mnemonic;
    wallet->m_primary_address = account.get_public_address_str(static_cast<cryptonote::network_type>(network_type));
    wallet->m_language = language;
    wallet->m_pub_view_key = epee::string_tools::pod_to_hex(keys.m_account_address.m_view_public_key);
    wallet->m_prv_view_key = epee::string_tools::pod_to_hex(keys.m_view_secret_key);
    wallet->m_pub_spend_key = epee::string_tools::pod_to_hex(keys.m_account_address.m_spend_public_key);
    wallet->m_prv_spend_key = epee::string_tools::pod_to_hex(keys.m_spend_secret_key);
    return wallet;
  }

  monero_wallet_keys* monero_wallet_keys::create_wallet_from_keys(const monero_network_type network_type, const string& address, const string& view_key, const string& spend_key, const string& language) {
    cout << "monero_wallet_keys::create_wallet_from_keys(...)" << endl;
    throw runtime_error("create_wallet_from_keys() not implemented");
  }

  // ----------------------------- WALLET METHODS -----------------------------

  monero_wallet_keys::~monero_wallet_keys() {
    MTRACE("~monero_wallet_keys()");
    close();
  }

  monero_version monero_wallet_keys::get_version() const {
    monero_version version;
    version.m_number = 65552; // same as monero-wallet-rpc v0.15.0.1 release
    version.m_is_release = false;     // TODO: could pull from MONERO_VERSION_IS_RELEASE in version.cpp
    return version;
  }

  monero_network_type monero_wallet_keys::get_network_type() const {
    throw runtime_error("monero_wallet_keys::get_network_type() not implemented");
  }

  string monero_wallet_keys::get_language() const {
    throw runtime_error("monero_wallet_keys::get_subaddresses() not implemented");
  }

  vector<string> monero_wallet_keys::get_languages() const {
    throw runtime_error("monero_wallet_keys::get_languages() not implemented");
  }

  string monero_wallet_keys::get_mnemonic() const {
    throw runtime_error("monero_wallet_keys::get_mnemonic() not implemented");
  }

  string monero_wallet_keys::get_public_view_key() const {
    throw runtime_error("monero_wallet_keys::get_public_view_key() not implemented");
  }

  string monero_wallet_keys::get_private_view_key() const {
    throw runtime_error("monero_wallet_keys::get_private_view_key() not implemented");
  }

  string monero_wallet_keys::get_public_spend_key() const {
    throw runtime_error("monero_wallet_keys::get_public_spend_key() not implemented");
  }

  string monero_wallet_keys::get_private_spend_key() const {
    throw runtime_error("monero_wallet_keys::get_private_spend_key() not implemented");
  }

  string monero_wallet_keys::get_address(uint32_t account_idx, uint32_t subaddress_idx) const {
    throw runtime_error("monero_wallet_keys::get_address() not implemented");
  }

  monero_subaddress monero_wallet_keys::get_address_index(const string& address) const {
    throw runtime_error("monero_wallet_keys::get_address_index() not implemented");
  }

  monero_integrated_address monero_wallet_keys::get_integrated_address(const string& standard_address, const string& payment_id) const {
    throw runtime_error("monero_wallet_keys::get_integrated_address() not implemented");
  }

  monero_integrated_address monero_wallet_keys::decode_integrated_address(const string& integrated_address) const {
    throw runtime_error("monero_wallet_keys::decode_integrated_address() not implemented");
  }

  vector<monero_account> monero_wallet_keys::get_accounts(bool include_subaddresses, const string& tag) const {
    throw runtime_error("monero_wallet_keys::get_accounts() not implemented");
  }

  monero_account monero_wallet_keys::get_account(uint32_t account_idx, bool include_subaddresses) const {
    throw runtime_error("monero_wallet_keys::get_subaddresses() not implemented");
  }

  monero_account monero_wallet_keys::create_account(const string& label) {
    throw runtime_error("monero_wallet_keys::get_account() not implemented");
  }

  vector<monero_subaddress> monero_wallet_keys::get_subaddresses(const uint32_t account_idx, const vector<uint32_t>& subaddress_indices) const {
    throw runtime_error("monero_wallet_keys::get_subaddresses() not implemented");
  }

  monero_subaddress monero_wallet_keys::get_subaddress(const uint32_t account_idx, const uint32_t subaddress_idx) const {
    throw runtime_error("monero_wallet_keys::get_subaddress() not implemented");
  }

  monero_subaddress monero_wallet_keys::create_subaddress(const uint32_t account_idx, const string& label) {
    throw runtime_error("monero_wallet_keys::create_subaddress() not implemented");
  }
  void monero_wallet_keys::close() {
    throw runtime_error("monero_wallet_keys::close() not implemented");
  }

  // ------------------------------- PRIVATE HELPERS ----------------------------
}
