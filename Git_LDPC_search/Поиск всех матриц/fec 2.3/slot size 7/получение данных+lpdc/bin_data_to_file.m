function bin_data_to_file(data, name)
   
data_str = "";
for i=1:length(data(:,1))
    for j = 1:length(data(1,:))
        data_str = append(data_str, num2str(data(i,j)));
        if(j == 10)|| (j == 40)|| (j == 56) || (j == 72)
            data_str = append(data_str, ' ');
        end
    end
    data_str = append(data_str, newline);
end
fp = fopen(name, "wt");
fprintf(fp, "%s", data_str);
fclose(fp);

end

