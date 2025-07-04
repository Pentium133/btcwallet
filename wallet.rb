require 'bitcoin'
require 'fileutils'
require 'json'
require 'net/http'
require 'uri'

class WalletApp
  def run
    loop do
      puts "\n1. Создать кошелек"
      puts "2. Баланс кошелька"
      puts "4. Выход"
      print "> Выберите действие: "
      case gets.chomp
      when "1"
        create
      when "2"
        get_balance
      when "4"
        break
      else
        puts "Некорректный выбор"
      end
    end
  end

  private

  def create
    Bitcoin.chain_params = :signet
    key = Bitcoin::Key.generate
    wif = key.to_wif
    pubkey = key.pubkey
    address = key.to_p2wpkh

    wallet_dir = "data"
    FileUtils.mkdir_p(wallet_dir)

    wallet_file = File.join(wallet_dir, "wallet.json")
    wallet_data = {
      wif: wif,
      pubkey: pubkey,
      address: address
    }
    File.write(wallet_file, JSON.pretty_generate(wallet_data))
  end

  def get_balance
    wallet_dir = "data"
    wallet_file = File.join(wallet_dir, "wallet.json")
    address = JSON.parse(File.read(wallet_file))['address']
    puts "Address: #{address}"

    # RPC параметры
    rpc_user = 'user'
    rpc_pass = 'pass'
    uri = URI('http://127.0.0.1:38332')

    request_body = {
      jsonrpc: '1.0',
      id: 'balance_check',
      method: 'scantxoutset',
      params: ['start', ["addr(#{address})"]]
    }.to_json

    req = Net::HTTP::Post.new(uri)
    req.basic_auth rpc_user, rpc_pass
    req.content_type = 'application/json'
    req.body = request_body
    res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }

    if res.is_a?(Net::HTTPSuccess)
      result = JSON.parse(res.body)
      amount = result.dig('result', 'total_amount')
      puts "Баланс: #{amount} BTC"
    else
      puts "Ошибка RPC: #{res.body}"
    end
  end
end