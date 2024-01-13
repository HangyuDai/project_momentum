clear
close all

return_m=readtable('return_monthly.xlsx','ReadVariableNames',true,'PreserveVariableNames',true,'Format','auto');
market_cap_lm=readtable('me_lag.xlsx','ReadVariableNames',true,'PreserveVariableNames',true,'Format','auto');

stacked_returns = stack(return_m, 3:width(return_m), 'NewDataVariableName', 'Returns', 'IndexVariableName', 'Date');
stacked_market_cap = stack(market_cap_lm, 3:width(return_m), 'NewDataVariableName', 'MarketCap', 'IndexVariableName', 'Date');

merged_data = innerjoin(stacked_returns, stacked_market_cap, 'Keys', {'code', 'Date'});
merged_data = removevars(merged_data, {'name_stacked_returns', 'name_stacked_market_cap'});
merged_data = rmmissing(merged_data, 'DataVariables', {'MarketCap'});