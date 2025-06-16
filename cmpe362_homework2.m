clear all;
close all;

% Defining parameters
window_size = 20;     % Window size for SMA (days)
alpha = 0.1;          % Smoothing factor for EMA (approx. 19-day equivalent)
analysis_days = 1000; % Number of days to analyze and plot

% The choice of a 20-day window for SMA and a smoothing factor (α) of 0.1 for EMA is well-justified for these banking stock analyses for several reasons:
% For the 20-day SMA window:
% 
% It strikes a balance between being responsive enough to capture meaningful price movements while filtering out daily market noise
% For banking stocks that tend to have institutional investors and moderate volatility patterns, 20 days captures approximately one month of trading (excluding weekends), aligning with typical monthly business cycles in banking
% It's short enough to be relevant for swing trading but long enough to avoid overreacting to temporary fluctuations
% 
% For the EMA smoothing factor α = 0.1:
% 
% This value corresponds to approximately a 19-day equivalent window (since α = 2/(N+1) N ≈ 19), making it comparable to the 20-day SMA for fair comparison
% A smaller α value (0.1) means less weight on the most recent prices and more weight on historical data, which suits the relatively stable but still reactive nature of banking stocks
% It provides sufficient smoothing for identifying trends while maintaining responsiveness


% Creating a ist of stock files to process
stock_files = {'KOTAKBANK.csv', 'HDFCBANK.csv', 'ICICIBANK.csv', 'INDUSINDBK.csv'};
num_stocks = length(stock_files);

% Processing each stock file
for file_idx = 1:num_stocks
    try
        % Loading and preprocessing the data
        filename = stock_files{file_idx};
        [stock_name, ~] = strtok(filename, '.');
        
        % Reading the table
        data = readtable(filename);
        
        % VWAP is in column 10
        vwap_col = 10;
        vwap = data{:, vwap_col};

        % --- SMA and EMA Calculation ---
        
        
        % Calculating Simple Moving Average (SMA)
        sma = zeros(size(vwap));
        for i = window_size:length(vwap)
            sma(i) = mean(vwap(i-window_size+1:i));
        end
        
        % Calculating Exponential Moving Average (EMA)
        ema = zeros(size(vwap));
        ema(1) = vwap(1);  % Initializing with first value
        for i = 2:length(vwap)
            ema(i) = alpha * vwap(i) + (1 - alpha) * ema(i-1);
        end
        
        % Creating a plot for each stock showing the last 1000 days
        figure('Name', [stock_name, ' Analysis'], 'Position', [100, 100, 1000, 600], 'Visible', 'on');
        
        % Extracting the last 1000 days
        total_days = length(vwap);
        start_idx = total_days - analysis_days + 1;
        date_range = start_idx:total_days;
        
        % Plotting the data according to the colors given in the guidelines
        plot(data.Date(date_range), vwap(date_range), 'b-', 'LineWidth', 1); hold on;
        plot(data.Date(date_range), sma(date_range), 'r-', 'LineWidth', 2);
        plot(data.Date(date_range), ema(date_range), 'g-', 'LineWidth', 2);
        
        % Adding title and labels to the plot
        title([stock_name, ' - Last ', num2str(length(date_range)), ' Trading Days']);
        xlabel('Date');
        ylabel('VWAP');
        legend('Original Price', ['SMA (', num2str(window_size), '-day)'], ...
               ['EMA (α=', num2str(alpha), ')'], 'Location', 'best');
        grid on;

        % Saving the plotted images (commented out cause it has already
        % been done once)

        % saveas(gcf, [stock_name, '_analysis.png']);
       
        % Ensuring the figure is displayed
        shg; 
        

        % --- MACD Calculation ---



        % Defining MACD parameters
        fast_period = 12;
        slow_period = 26;
        signal_period = 9;
        
        % Calculating Fast and Slow EMAs using the same alpha-based logic
        alpha_fast = 2 / (fast_period + 1);
        alpha_slow = 2 / (slow_period + 1);
        alpha_signal = 2 / (signal_period + 1);
        
        % Computing EMA Fast
        ema_fast = zeros(size(vwap));
        ema_fast(1) = vwap(1);
        for i = 2:length(vwap)
            ema_fast(i) = alpha_fast * vwap(i) + (1 - alpha_fast) * ema_fast(i-1);
        end
        
        % Computing EMA Slow
        ema_slow = zeros(size(vwap));
        ema_slow(1) = vwap(1);
        for i = 2:length(vwap)
            ema_slow(i) = alpha_slow * vwap(i) + (1 - alpha_slow) * ema_slow(i-1);
        end
        
        % Computing MACD Line
        macd_line = ema_fast - ema_slow;
        
        % Computing Signal Line (EMA of MACD line)
        signal_line = zeros(size(macd_line));
        signal_line(1) = macd_line(1);
        for i = 2:length(macd_line)
            signal_line(i) = alpha_signal * macd_line(i) + (1 - alpha_signal) * signal_line(i-1);
        end
        
        % Computing Histogram
        macd_histogram = macd_line - signal_line;
        % Plot MACD and Signal Line
        figure('Name', [stock_name, ' MACD Analysis'], 'Position', [150, 150, 1000, 500]);

        % Plotting MACD line and Signal line
        plot(data.Date(date_range), macd_line(date_range), 'b-', 'LineWidth', 1.5); hold on;
        plot(data.Date(date_range), signal_line(date_range), 'r--', 'LineWidth', 1.5);

        % Plotting Histogram
        bar(data.Date(date_range), macd_histogram(date_range), 'FaceColor', [0.6 0.6 0.6], 'EdgeColor', 'none');

        title([stock_name, ' - MACD (Last ', num2str(length(date_range)), ' Days)']);
        xlabel('Date'); ylabel('MACD Value');
        legend('MACD Line', 'Signal Line', 'MACD Histogram');
        grid on;

        % Saving the plotted images (commented out cause it has already
        % been done once)

        %saveas(gcf, [stock_name, '_macd_analysis.png']);



        % --- Algorithmic Trading Strategy ---

        % Setting the initial parameters
        initial_balance = 10000;
        cash = initial_balance;
        shares = 0;
        portfolio_value = zeros(600, 1);
        log_file = fopen([stock_name '_trading_log.txt'], 'w');
        
        sim_days = 600;
        total_days = length(vwap);
        start_idx = total_days - sim_days + 1;
        
        % Extracting the last 600 days
        v = vwap(start_idx:end);
        macd = macd_line(start_idx:end);
        signal = signal_line(start_idx:end);
        ema_last600 = ema(start_idx:end);
        sma_last600 = sma(start_idx:end);

        for t = 2:sim_days
            ema_prev = ema_last600(t-1); 
            sma_prev = sma_last600(t-1);
            ema_now = ema_last600(t);    
            sma_now = sma_last600(t);
            % Previous and current MACD/signal values
            macd_prev = macd(t-1);
            signal_prev = signal(t-1);
            macd_now = macd(t);
            signal_now = signal(t);
            
            % Use SMA and EMA for confirmation
            price_now = v(t);  % Current price of the stock
            price_prev = v(t-1);  % Previous day's price
            
            action = '';
            
            % Buy signal: MACD crosses above Signal line and the current
            % price is higher than the current EMA and SMA
            if macd_prev < signal_prev && macd_now > signal_now && price_now > ema_now && price_now > sma_now
                invest_amount = 0.2 * cash;  % Invest 20% of available cash
                shares_bought = invest_amount / price_now;
                shares = shares + shares_bought;
                cash = cash - invest_amount;
                action = sprintf('BUY %.2f currency of %s (%.4f shares @ %.2f)', invest_amount, stock_name, shares_bought, price_now);
                
            % Sell signal: MACD crosses below Signal line and the current
            % price is lower than the current EMA and SMA
            % below SMA line
            elseif macd_prev > signal_prev && macd_now < signal_now && price_now < ema_now && price_now < sma_now
                sell_amount = 0.2 * shares;  % Sell 20% of the shares
                cash_gain = sell_amount * price_now;
                shares = shares - sell_amount;
                cash = cash + cash_gain;
                action = sprintf('SELL %.2f currency of %s (%.4f shares @ %.2f)', cash_gain, stock_name, sell_amount, price_now);
            end
            
            % Log if there was a trade
            if ~isempty(action)
                fprintf(log_file, 'Day %d (%s): %s\n', t, data.Date(start_idx + t - 1), action);
            end
            
            % Record total portfolio value for plotting/report
            portfolio_value(t) = cash + shares * price_now;
        end
        
        fclose(log_file);  % Close the log file after the simulation

        
        
        
        % Final report
        final_value = cash + shares * v(end);
        fprintf('Final Net Worth for %s: %.2f\n', stock_name, final_value);

        
    catch err
        fprintf('Error processing %s: %s\n', stock_files{file_idx}, err.message);
        fprintf('Stack trace:\n');
        disp(err.stack);
        fprintf('Continuing with next file...\n\n');
    end
end
