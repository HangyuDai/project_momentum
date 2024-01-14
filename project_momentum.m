clear
close all

return_monthly=readtable('return_monthly.xlsx','ReadVariableNames',true,'PreserveVariableNames',true,'Format','auto');
market_cap_lm=readtable('me_lag.xlsx','ReadVariableNames',true,'PreserveVariableNames',true,'Format','auto');

stacked_returns = stack(return_monthly, 3:width(return_monthly), 'NewDataVariableName', 'Returns', 'IndexVariableName', 'Date');
stacked_market_cap = stack(market_cap_lm, 3:width(return_monthly), 'NewDataVariableName', 'MarketCap', 'IndexVariableName', 'Date');

merged_data = innerjoin(stacked_returns, stacked_market_cap, 'Keys', {'code', 'Date'});
merged_data = removevars(merged_data, {'name_stacked_returns', 'name_stacked_market_cap'});
merged_data = rmmissing(merged_data, 'DataVariables', {'MarketCap'});

return_m = merged_data;

frequency = [1, 3, 6, 12, 24];

[G,jdate]=findgroups(return_m.Date);
num_obs=length(jdate);

return_m.jdate=G;

mom_old=table();

for i = 3
    % frequency = 3
    for j=[i: num_obs-1]
        % pick up previous frequency(i) months returns
         temp_date=[j-i+1:j];
         start_date=j+1;
        index_i=(return_m.jdate==temp_date);
        index=logical(sum(index_i,2));
        mom_sample=return_m(index,1:end);

       % calculate the previous months' cumulative return
       [G,code]=findgroups(mom_sample.code);
       pr_return=splitapply(@(x)sum(x),mom_sample.Returns,G);
       pr_return_table=table(code,pr_return);
       % merge it back to mom_sample to enhance the vector of previous return
       
       index_r=(return_m.jdate==start_date);
       mom_r=return_m(index_r,1:end);

       mom_sample1=outerjoin(mom_r,pr_return_table,'Keys',{'code'},'MergeKeys',true,'Type','left');
       
       % merge the sample back to the full dataset for each iteration
       
       return_full=vertcat(mom_old, mom_sample1);
       
       mom_old=return_full;
        
    end

end

%%

%% Task b)

% Create percentiles functions, using anonymous functions and the prctile_
% function for prctile_20, prctile_40, prctile_60, prctile_80) 

for i=20:20:80
   eval(['prctile_',num2str(i),'=','@(input)prctile(input,i)',';']);
end

% Calcualte percentiles
%Applies the function mom_bucket_5 to each row of the specified columns.
% Create a new variable mom_label in return_full based on the function output.


for x=20:20:80
                eval(['b','=','prctile_',num2str(x),'(return_full.pr_return)',';']);
                eval(['return_full.mom',num2str(x),'=','b*ones(size(return_full,1),1)',';']);
end

return_full.mom_label=rowfun(@mom_bucket_5,return_full(:,{'pr_return','mom20','mom40','mom60'...
                ,'mom80'}),'OutputFormat','cell');
   
% ceate equal-weighted portfolio

return_full.ew=ones(size(return_full,1),1);        
           
% Grouping anc computing equal-weighted returns
            
[G,jdate,mom_label]=findgroups(return_full.Date, return_full.mom_label);

ewret=splitapply(@wavg,return_full(:,{'pr_return','ew'}),G);

ewret_table=table(jdate,mom_label,ewret);

% unstack data and compute av returns
% computes the av returns for the low and high previous return groups (A and E, respectively)

mom_factors=unstack(ewret_table(:,{'ewret','jdate','mom_label'}),'ewret','mom_label');

A=nanmean(table2array(mom_factors(:,2)))*100;

E=nanmean(table2array(mom_factors(:,6)))*100;

% display results

fprintf('The average return for the low previous return group is %4.3f percent per month \n',A)

fprintf('The average return for the high previous return group is %4.3f percent per month \n',E)


% The output shows that: 
%The average return for the low previous return group is -2185.032 percent per month 
%The average return for the high previous return group is 3734.668 percent per month

% based on the observed return spread, it seems that there is evidence of momentum in Chinese stock markets. 
% The positive return spread suggests a potential momentum effect
% Past winners continue to outperform past losers over the specified holding periods.