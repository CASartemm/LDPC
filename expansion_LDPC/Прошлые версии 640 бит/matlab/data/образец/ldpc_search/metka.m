clear;

Slots = load("trueSlots.mat");
Slots = Slots.Slots_2pi2;
% load("Slots_pi2_count_len.mat");
% load("Slots_2pi2_count_len.mat");
% load("Slots_3pi2_count_len.mat");

Scrembler = load("trueScrembler.mat");
Scrembler = Scrembler.Scrembler1;
% load("Scrembler2.mat");
% load("Scrembler3.mat");
% load("Scrembler4.mat");


%====================================================================
%====================================================================

for i=1:1000
    data_check1(i,:) = demodqpsk(Slots(i,1:end));
    % data_check2(i,:) = demodqpsk(Slots_pi2(i,1:end));
    % data_check3(i,:) = demodqpsk(Slots_2pi2(i,1:end));
    % data_check4(i,:) = demodqpsk(Slots_3pi2(i,1:end));
end



data = uniqWord(Slots(1,:));
for i=1:length(data_check1(:,1))
    for j = 1:length(data_check1(1,:))
        data = append(data, num2str(data_check1(i,j)));
        if(j == 10)|| (j == 40)|| (j == 56) || (j == 72)
            data = append(data, ' ');
        end
    end
    data = append(data, newline);
end
fp = fopen("d_true.txt", "wt");
fprintf(fp, "%s", data);
fclose(fp);


% data = uniqWord(Slots_pi2(1,:));
% for i=1:length(data_check2(:,1))
%     for j = 1:length(data_check2(1,:))
%         data = append(data, num2str(data_check2(i,j)));
%         if(j == 10)|| (j == 40)|| (j == 56) || (j == 72)
%             data = append(data, ' ');
%         end
%     end
%     data = append(data, newline);
% end
% fp = fopen("d2_count_len.txt", "wt");
% fprintf(fp, "%s", data);
% fclose(fp);
% 
% 
% 
% data = uniqWord(Slots_2pi2(1,:));
% for i=1:length(data_check3(:,1))
%     for j = 1:length(data_check3(1,:))
%         data = append(data, num2str(data_check3(i,j)));
%         if(j == 10)|| (j == 40)|| (j == 56) || (j == 72)
%             data = append(data, ' ');
%         end
%     end
%     data = append(data, newline);
% end
% fp = fopen("d3_count_len.txt", "wt");
% fprintf(fp, "%s", data);
% fclose(fp);
% 
% 
% data = uniqWord(Slots_3pi2(1,:));
% for i=1:length(data_check4(:,1))
%     for j = 1:length(data_check4(1,:))
%         data = append(data, num2str(data_check4(i,j)));
%         if(j == 10)|| (j == 40)|| (j == 56) || (j == 72)
%             data = append(data, ' ');
%         end
%     end
%     data = append(data, newline);
% end
% fp = fopen("d4_count_len.txt", "wt");
% fprintf(fp, "%s", data);
% fclose(fp);



%==============================================
%дескремблированные слоты
%=============================================
dataLen = 640;

seq = Scrembler.genSeq(dataLen); %сравнил по хедору какие созвездия совпадают. 
% seq3 = Scrembler2.genSeq(dataLen);
% seq4 = Scrembler3.genSeq(dataLen);
% seq1 = Scrembler4.genSeq(dataLen);

data = uniqWord(Slots(1,:));
for i=1:length(data_check1(:,1))
    for j = 1:length(data_check1(1,:))
        if(j<=40) || (j > dataLen)
            data = append(data, num2str(data_check1(i,j)));
        else
            data = append(data, num2str(xor(data_check1(i,j),seq(j-40))));
        end
        if(j == 10)|| (j == 40)|| (j == 56) || (j == 72)
            data = append(data, ' ');
        end
    end
    data = append(data, newline);
end
fp = fopen("d_true_descrembl.txt", "wt");
fprintf(fp, "%s", data);
fclose(fp);


% data = uniqWord(Slots_pi2(1,:));
% for i=1:length(data_check2(:,1))
%     for j = 1:length(data_check2(1,:))
%         if(j<=40) || (j > dataLen)
%             data = append(data, num2str(data_check2(i,j)));
%         else
%             data = append(data, num2str(xor(data_check2(i,j),seq2(j-40))));
%         end
%         if(j == 10)|| (j == 40)|| (j == 56) || (j == 72)
%             data = append(data, ' ');
%         end
%     end
%     data = append(data, newline);
% end
% fp = fopen("d2_count_len_descrembl.txt", "wt");
% fprintf(fp, "%s", data);
% fclose(fp);
% 
% 
% 
% data = uniqWord(Slots_2pi2(1,:));
% for i=1:length(data_check3(:,1))
%     for j = 1:length(data_check3(1,:))
%         if(j<=40) || (j > dataLen)
%             data = append(data, num2str(data_check3(i,j)));
%         else
%             data = append(data, num2str(xor(data_check3(i,j),seq3(j-40))));
%         end
%         if(j == 10)|| (j == 40)|| (j == 56) || (j == 72)
%             data = append(data, ' ');
%         end
%     end
%     data = append(data, newline);
% end
% fp = fopen("d3_count_len_descrembl.txt", "wt");
% fprintf(fp, "%s", data);
% fclose(fp);
% 
% 
% data = uniqWord(Slots_3pi2(1,:));
% for i=1:length(data_check4(:,1))
%     for j = 1:length(data_check4(1,:))
%         if(j<=40) || (j > dataLen)
%             data = append(data, num2str(data_check4(i,j)));
%         else
%             data = append(data, num2str(xor(data_check4(i,j),seq4(j-40))));
%         end
%         if(j == 10)|| (j == 40)|| (j == 56) || (j == 72)
%             data = append(data, ' ');
%         end
%     end
%     data = append(data, newline);
% end
% fp = fopen("d4_count_len_descrembl.txt", "wt");
% fprintf(fp, "%s", data);
% fclose(fp);


