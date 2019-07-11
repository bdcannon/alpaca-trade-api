# frozen_string_literal: true

RSpec.describe Alpaca::Trade::Api::Client do
  describe '.initialize' do
    it 'defaults to configuration' do
      expect(subject.endpoint).to eq(Alpaca::Trade::Api.configuration.endpoint)
      expect(subject.key_id).to eq(Alpaca::Trade::Api.configuration.key_id)
      expect(subject.key_secret).to eq(Alpaca::Trade::Api.configuration.key_secret)
    end

    it 'accepts overwriting configuration' do
      client = described_class.new(endpoint: 'a', key_id: 'b', key_secret: 'c')
      expect(client.endpoint).to eq('a')
      expect(client.key_id).to eq('b')
      expect(client.key_secret).to eq('c')
    end
  end

  describe '#account' do
    it 'returns an Account object', :vcr do
      account = subject.account
      expect(account.status).to eq('ACTIVE')
      expect(account.currency).to eq('USD')
      expect(account.pattern_day_trader).to be_falsy
    end

    it 'raises UnauthorizedError when status code is 401', :vcr do
      subject = described_class.new(key_secret: 'wrong')
      expect { subject.account }.to raise_error(Alpaca::Trade::Api::UnauthorizedError)
    end

    it 'raises RateLimitedError when status code is 429'
    it 'raises InternalServerError when status code is 500'
  end

  describe '#asset' do
    it 'returns an Asset object', :vcr do
      asset = subject.asset(symbol: 'CRM')
      expect(asset.asset_class).to eq('us_equity')
      expect(asset.tradable).to be_truthy
    end
  end

  describe '#assets' do
    it 'returns an Array of Asset objects', :vcr do
      assets = subject.assets
      expect(assets).to be_an(Array)
      expect(assets.first).to be_an(Alpaca::Trade::Api::Asset)
    end

    it 'filters assets by status and asset_class', :vcr do
      assets = subject.assets(status: 'active', asset_class: 'us_equity')
      expect(assets).to be_an(Array)
      expect(assets.first).to be_an(Alpaca::Trade::Api::Asset)
    end
  end

  describe '#bars' do
    it 'returns Bar objects for one symbol', :vcr do
      bars = subject.bars('1D', ['CRM'])
      expect(bars['CRM']).to be_an(Array)

      bar = bars['CRM'].first
      expect(bar).to be_an(Alpaca::Trade::Api::Bar)
    end

    it 'returns Bar objects for multiple symbols', :vcr do
      bars = subject.bars('1D', %w[CRM FB AMZN])
      expect(bars['FB']).to be_an(Array)

      bar = bars['AMZN'].first
      expect(bar).to be_an(Alpaca::Trade::Api::Bar)
    end
  end

  describe '#calendar' do
    it 'returns Calendar objects', :vcr do
      market_calendar = subject.calendar(start_date: Date.new(2019,6,1), end_date: Date.new(2019,7,1))
      expect(market_calendar).to be_an(Array)
      expect(market_calendar.size).to eq(21)
      expect(market_calendar.first).to be_an(Alpaca::Trade::Api::Calendar)
    end
  end

  describe '#cancel_order' do
    it 'cancels an existing order'
    it 'raises an exception when order id is invalid'
    it 'raises an exception when order is not cancelable'
  end

  describe '#new_order' do
    it 'places a new Order', :vcr do
      order = subject.new_order(symbol: 'AAPL',
                                qty: 5,
                                side: 'buy',
                                type: 'limit',
                                time_in_force: 'day',
                                limit_price: 200,
                                extended_hours: true,
                                client_order_id: 'MY_ORDER_ID')
      expect(order).to be_an(Alpaca::Trade::Api::Order)
      expect(order.id).to_not be_nil
    end

    it 'raises an exception when buying power is not sufficient', :vcr do
      expect { subject.new_order(symbol: 'AAPL',
                                 qty: 5_000,
                                 side: 'buy',
                                 type: 'limit',
                                 time_in_force: 'day',
                                 limit_price: 200,
                                 extended_hours: true) }.to raise_error(Alpaca::Trade::Api::InsufficientFunds)
    end

    it 'raises an exception when required parameters are not provided', :vcr do
      expect { subject.new_order(symbol: 'AAPL',
                                 qty: 5,
                                 side: 'buy',
                                 type: 'limit',
                                 time_in_force: 'day',
                                 extended_hours: true,
                                 client_order_id: 'MY_ORDER_ID_2') }.to raise_error(Alpaca::Trade::Api::MissingParameters)
    end
  end

  describe '#clock' do
    it 'returns the market clock', :vcr do
      clock = subject.clock
      expect(clock).to be_an(Alpaca::Trade::Api::Clock)
    end
  end

  describe '#order' do
    let(:invalid_id) { '001c0b29-5bc9-45c4-bd32-5ba323c997b3' }
    let(:valid_id) { 'f08bfc92-c922-41f9-8166-3657e5bedef0' }

    it 'returns an Order object', :vcr do
      order = subject.order(id: valid_id)
      expect(order).to be_an(Alpaca::Trade::Api::Order)
    end

    it 'raises an exception when order id is invalid', :vcr do
      expect { subject.order(id: invalid_id) }.to raise_error(Alpaca::Trade::Api::InvalidOrderId)
    end
  end

  describe '#orders' do
    it 'returns an Array of Order objects', :vcr do
      orders = subject.orders(status: 'all', limit: 5)
      expect(orders).to be_an(Array)
      expect(orders.size).to eq(5)
      expect(orders.first).to be_an(Alpaca::Trade::Api::Order)
    end
  end

  describe '#position' do
    it 'returns a Position object', :vcr do
      position = subject.position(symbol: 'FB')
      expect(position).to be_an(Alpaca::Trade::Api::Position)
    end

    it 'raises an exception when position is not found for symbol', :vcr do
      expect { subject.position(symbol: 'CRM') }.to raise_error(Alpaca::Trade::Api::NoPositionForSymbol)
    end
  end

  describe '#positions' do
    it 'returns an Array of Position objects with open positions', :vcr do
      positions = subject.positions
      expect(positions).to be_an(Array)
      expect(positions.first).to be_an(Alpaca::Trade::Api::Position)
    end
  end
end
