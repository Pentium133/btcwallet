require 'bitcoin'
require 'fileutils'
require 'json'

class WalletApp
  def run
    loop do
      puts "\n1. Создать кошелек"
      puts "4. Выход"
      print "> Выберите действие: "
      case gets.chomp
      when "1"
        create_wallet
      when "2"
        break
      else
        puts "Некорректный выбор"
      end
    end
  end

  private

  def create_wallet
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
end