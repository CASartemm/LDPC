clear;

Slots = load("Slots_960.mat");
Slots = Slots.Slots;


%====================================================================
%====================================================================

for i=1:length(Slots(:,1))
    data_scr(i,:) = demodqpsk_istar(Slots(i,1:end));
end


dataLen = length(data_scr(1,41:end));
seqA = scrembler_istar([1 0 0 1 0 1 0 1 0 1 0 1 1 1 1], dataLen);
                        
seqB = scrembler_istar([0 0 0 1 1 1 0 0 0 1 1 1 0 0 0], dataLen);



for i=1:length(data_scr(:,1))
    for j = 41:length(data_scr(1,:)) %пропускаем уникальное слово и не скремблируем его
       if (mod(j,2) == 1)
           data_descr(i,j) = xor(data_scr(i,j),seqA(fix((j - 40)/2)+1));
       else
           data_descr(i,j) = xor(data_scr(i,j),seqB(fix((j - 40)/2)  ));
       end
    end
    
end


bin_data_to_file(data_descr, "data_960_Scrembled_bin.txt");

%hex_data_to_file(data, "data_640_Scrembled_hex.txt");