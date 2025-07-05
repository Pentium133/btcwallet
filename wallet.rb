# frozen_string_literal: true

require 'bitcoin'
require 'fileutils'
require 'json'
require 'net/http'
require 'uri'
require 'digest'

class WalletApp
  WALLET_FILE = 'data/wallet.json'

  def run
    loop do
      puts "\n1. Создать кошелек"
      puts '2. Баланс кошелька'
      puts '3. Отправить BTC'
      puts '5. Выход'
      print '> Выберите действие: '
      case gets.chomp
      when '1'
        create
      when '2'
        get_balance
      when '3'
        send_to_address
      when '5'
        break
      else
        puts 'Некорректный выбор'
      end
    end
  end

  private

  def save_wallet(data)
    FileUtils.mkdir_p('data')
    File.write(WALLET_FILE, JSON.pretty_generate(data))
  end

  def load_wallet
    return nil unless File.exist?(WALLET_FILE)

    JSON.parse(File.read(WALLET_FILE))
  end

  def create
    if File.exist?(WALLET_FILE)
      puts 'Кошелек уже существует!'
      return
    end
    Bitcoin.chain_params = :signet
    key = Bitcoin::Key.generate
    wif = key.to_wif
    pubkey = key.pubkey
    pubkey_bytes = [key.pubkey].pack('H*')
    puts "pubkey_bytes length: #{pubkey_bytes.bytesize}" # должно быть 33
    change_address = key.to_p2wpkh
    Bitcoin::Script.parse_from_addr(change_address)
    address = key.to_p2wpkh

    wallet_data = {
      wif: wif,
      pubkey: pubkey,
      address: address
    }

    save_wallet(wallet_data)
    puts "Кошелек создан! Адрес: #{address}"
  end

  def get_balance
    wallet_data = load_wallet
    unless wallet_data
      puts 'Кошелек не найден! Создайте кошелек.'
      return
    end

    address = wallet_data['address']
    puts "Address: #{address}"

    url = URI("https://mempool.space/signet/api/address/#{address}")
    res = Net::HTTP.get_response(url)

    if res.is_a?(Net::HTTPSuccess)
      data = JSON.parse(res.body)

      funded = data['chain_stats']['funded_txo_sum']
      spent  = data['chain_stats']['spent_txo_sum']
      mempool_funded = data['mempool_stats']['funded_txo_sum']
      mempool_spent  = data['mempool_stats']['spent_txo_sum']

      balance_sats = funded - spent + mempool_funded - mempool_spent
      balance_btc = balance_sats.to_f / 100_000_000

      puts "Баланс адреса: #{balance_btc} BTC"
      balance_btc
    else
      puts "Ошибка получения баланса: #{res.body}"
      nil
    end
  end

  # Создание и отправка raw-транзакции через mempool.space
  def send_to_address(to_address = 'tb1q9y30addnhhr0hrqxstz2jtwnle7lgvvgae2lh9', amount_btc = 0.0003)
    wallet_data = load_wallet
    unless wallet_data && wallet_data['wif'] && wallet_data['address']
      puts 'Нет приватного ключа или адреса в кошельке!'
      return
    end
    wif = wallet_data['wif']
    from_address = wallet_data['address']

    utxo = fetch_utxo(from_address)
    unless utxo
      puts "Нет доступных UTXO для адреса #{from_address}"
      return
    end

    utxo_txid = utxo[:txid]
    utxo_vout = utxo[:vout]
    utxo_amount = utxo[:value]
    fee = 10_000
    amount = (amount_btc * 100_000_000).to_i

    if utxo_amount < amount + fee
      puts 'Недостаточно средств для отправки!'
      return
    end

    Bitcoin::Tx.new
    raw_hex = create_raw_tx(wif, utxo_txid, utxo_vout, utxo_amount, to_address, amount, fee, from_address)
    puts "Raw hex транзакции: #{raw_hex}"

    url = URI('https://mempool.space/signet/api/tx')
    req = Net::HTTP::Post.new(url)
    req.body = raw_hex
    req.content_type = 'text/plain'
    res = Net::HTTP.start(url.hostname, url.port, use_ssl: true) { |http| http.request(req) }

    if res.is_a?(Net::HTTPSuccess)
      puts "Транзакция отправлена! TXID: #{res.body}"
      res.body
    else
      puts "Ошибка отправки: #{res.body}"
      nil
    end
  end

  def create_raw_tx(wif, utxo_txid, utxo_vout, utxo_amount, to_address, amount, fee, _from_address)
    Bitcoin.chain_params = :signet
    key = Bitcoin::Key.from_wif(wif)
    pubkey_bytes = [key.pubkey].pack('H*')
    puts "pubkey_bytes (hex): #{pubkey_bytes.unpack1('H*')}"
    puts "pubkey_bytes length: #{pubkey_bytes.bytesize}"

    pubkey_hash = Digest::RMD160.digest(Digest::SHA256.digest(pubkey_bytes))
    puts "pubkey_hash (hex): #{pubkey_hash.unpack1('H*')}"
    puts "pubkey_hash length: #{pubkey_hash.bytesize}"
    change_address = key.to_p2wpkh
    change = utxo_amount - amount - fee

    tx = Bitcoin::Tx.new
    tx_in = Bitcoin::TxIn.new
    tx_in.out_point = Bitcoin::OutPoint.from_txid(utxo_txid, utxo_vout)
    tx_in.script_sig = Bitcoin::Script.new
    tx_in.sequence = 0xffffffff
    tx.inputs << tx_in

    script_pubkey = Bitcoin::Script.parse_from_addr(to_address)
    tx_out = Bitcoin::TxOut.new
    tx_out.value = amount
    tx_out.script_pubkey = script_pubkey
    tx.outputs << tx_out

    if change.positive?
      change_script = Bitcoin::Script.parse_from_addr(change_address)
      change_out = Bitcoin::TxOut.new
      change_out.value = change
      change_out.script_pubkey = change_script
      tx.outputs << change_out
    end

    script_code = Bitcoin::Script.new
    script_code << Bitcoin::Opcodes::OP_DUP
    script_code << Bitcoin::Opcodes::OP_HASH160
    script_code << pubkey_hash
    script_code << Bitcoin::Opcodes::OP_EQUALVERIFY
    script_code << Bitcoin::Opcodes::OP_CHECKSIG

    sighash_type = Bitcoin::SIGHASH_TYPE[:all]
    sighash = tx.sighash_for_input(0, script_code, amount: utxo_amount, sig_version: :witness_v0,
                                                   hash_type: sighash_type)
    signature = key.sign(sighash) + [sighash_type].pack('C')
    tx.inputs[0].script_witness = Bitcoin::ScriptWitness.new([signature, pubkey_bytes])

    tx.to_payload.bth
  end

  def fetch_utxo(address)
    url = URI("https://mempool.space/signet/api/address/#{address}/utxo")
    res = Net::HTTP.get_response(url)
    unless res.is_a?(Net::HTTPSuccess)
      puts "Ошибка получения UTXO: #{res.body}"
      return nil
    end
    utxos = JSON.parse(res.body)
    return nil if utxos.empty?

    # Берём первый UTXO (или реализуйте выбор по сумме)
    utxo = utxos.first
    {
      txid: utxo['txid'],
      vout: utxo['vout'],
      value: utxo['value'] # в сатоши
    }
  end
end
