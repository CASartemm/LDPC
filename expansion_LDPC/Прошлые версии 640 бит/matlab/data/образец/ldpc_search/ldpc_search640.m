clear;

% f = fopen('D:\ISTAR\Matlab_tdma\замеры TDMA\analog_rand4.csv','r');
% A = fscanf(f,'%f,%f,%f,%f,%f',[5 Inf]);
% A = A';
% A(:,1) = [];
% 
% Q = A(:,1)- A(:,2);
% I = A(:,4)- A(:,3);
% 
% I = I/max(abs(I));
% Q = Q/max(abs(Q));
% 
% rxfilter = comm.RaisedCosineReceiveFilter('InputSamplesPerSymbol',50, ...
%     'DecimationFactor',1,'Shape','Square root','RolloffFactor',0.2, 'FilterSpanInSymbols',10, 'DecimationOffset',0);
% 
% 
% postRxI = rxfilter(I);
% postRxQ = rxfilter(Q);
% 
% SymbolSync = comm.SymbolSynchronizer("SamplesPerSymbol", 50, "NormalizedLoopBandwidth", 0.01, "DetectorGain", 2.7, "TimingErrorDetector", "Gardner (non-data-aided)");
% B=SymbolSync(postRxI+1i*postRxQ);
% 
% 




% ============================================================================
% что бы сократить вычисления, прикладываю сразу файл В.mat. Он содержит 600
% мс запись слотов со слот сайзом 2 и FEC 5/6. Каждый слот с рандомными
% данными и уникальный. Как будет видно дальше, получилось 1267 уникальных слотов.
% На 640 ищем матрицу P аналитическим способом, а на остальных 620 слотах
% проверяем, что P работает


load('B_rand_len2.mat');

A=zeros(1,numel(B));

%for m=0:3000
    m=2775; %для этого файла была подобрана такая фаза
    dphi=m*0.0000005;    
    phi=0;
    for k=1:numel(A)
        phi=phi+dphi;
        A(k)=B(k)*(cos(phi)+1i*sin(phi));
    end
    plot(A(3000:600000),'o');
%     pause(0.001);
%     disp(m);
% end
  alfa = 0.63;
  A=A*(cos(alfa)-1i*sin(alfa));
  plot(A(3000:600000),'o');

C=A(3000:600000);
C=1.3*C/max(abs(C)); %разброс значений большой, т.к. запись длиинная, поэтому коэф 1.1 что бы значения были больше 0.5
figure; hold on;
plot(C,'o');


for i=1:numel(C)
    if (abs(real(C(i)))<0.2)
        C(i)=0;
    end
    if real(C(i))>0.5 && imag(C(i))>0.5
        C(i)=1+1i*1;
    end
    if real(C(i))>0.5 && imag(C(i))<-0.5
        C(i)=1-1i*1;
    end
    if real(C(i))<-0.5 && imag(C(i))>0.5
        C(i)=-1+1i*1;
    end
    if real(C(i))<-0.5 && imag(C(i))<0.5
        C(i)=-1-1i*1;
    end
end

%смотрим на графике, что все значения определились верно и нет тех, которые
%мимо диапазона
figure; hold on;
plot(C,'o');

StartFound=0;
SlotsNum=0;
Starts=zeros(1,100);
Ends=zeros(1,100);
for i=1:numel(C)-1
    if real(C(i))==0 && real(C(i+1))~=0        
        Starts(SlotsNum+1)=i+1;
        StartFound=1;
    end
    if real(C(i))~=0 && real(C(i+1))==0 && StartFound
        SlotsNum=SlotsNum+1;
        Ends(SlotsNum)=i;
    end
end

SlotSize=Ends(1)-Starts(1)+1;
Slots=zeros(SlotsNum,SlotSize);

for i=1:SlotsNum
    Slots(i,:)=C(Starts(i):Ends(i));
end


%Крутим и рассматриваем все 4 варианта вместе с заголовком и меткой
Slots_pi2 = Slots*(0-1i*1);
Slots_2pi2 = Slots_pi2*(0-1i*1);
Slots_3pi2 = Slots_2pi2*(0-1i*1);

% 
% % load("Slots_count_len.mat");
% % load("Slots_pi2_count_len.mat");
% % load("Slots_2pi2_count_len.mat");
% % load("Slots_3pi2_count_len.mat");
% % 
% % 
% % %============================================
% % демодулирую слоты для всех 4 вариантов слотов
for i=1:640
    %d1(i,:) = demodqpsk(Slots(i,21:end));
    %d2(i,:) = demodqpsk(Slots_pi2(i,21:end));
    d3(i,:) = demodqpsk(Slots_2pi2(i,21:end));
    %d4(i,:) = demodqpsk(Slots_3pi2(i,21:end));
end



% 
% 
% %===============================================
% %решение линейного уравнения в поле Галуа функцией gflineq для каждого
% %столбца LDPC. Ищем матрицу P, составляющую часть пораждающей матрицы G = [I P]
% %Сразу пытаемся найти матрицу 640 на 132, а не на 128. Т.к. слоты размером
% %772 бита или 772 - 640 = 132. На 4 больше 128. Как будет видно дальше,
% %матрица P для 132 бит будет найдена во всех 4 случаях

for i=1:128+4 
    %P1(:,i) = gflineq(d1(:,1:640),d1(:,640+i));
    %P2(:,i) = gflineq(d2(:,1:640),d2(:,640+i));
    P3(:,i) = gflineq(d3(:,1:640),d3(:,640+i));
    %P4(:,i) = gflineq(d4(:,1:640),d4(:,640+i));
end
% 
% rank1 = rank(d1(:,1:640));
% rank2 = rank(d2(:,1:640));
 rank3 = rank(d3(:,1:640));
% rank4 = rank(d4(:,1:640));
% 
% det1 = det(d1(:,1:640));
% det2 = det(d2(:,1:640));
 det3 = det(d3(:,1:640));
% det4 = det(d4(:,1:640));
% 
% % pcolor(P1);
% % %imagesc(P2);
% % 
% % figure; hold on; spy(P1'); spy(P3', 'red');
% % 
% % nnz(sparse(P2));
% 
% % 
% % %======================================================================
% % % Записываю полученные P матрицы в файлы для удобства сранения между собой.
% % % Так видно все 132 столбца на одном экране.
% % data = "";
% % for i=1:length(P1(:,1))
% %     for j = 1:length(P1(1,:))
% %         data = append(data, num2str(P1(i,j)));
% %     end
% %     data = append(data, newline);
% % end
% % fp = fopen("P1_count_len.txt", "wt");
% % fprintf(fp, "%s", data);
% % fclose(fp);
% % 
% % 
% % 
% % data = "";
% % for i=1:length(P2(:,1))
% %     for j = 1:length(P2(1,:))
% %         data = append(data, num2str(P2(i,j)));
% %     end
% %     data = append(data, newline);
% % end
% % fp = fopen("P2_count_len.txt", "wt");
% % fprintf(fp, "%s", data);
% % fclose(fp);
% % 
% % 
% % 
% % data = "";
% % for i=1:length(P3(:,1))
% %     for j = 1:length(P3(1,:))
% %         data = append(data, num2str(P3(i,j)));
% %     end
% %     data = append(data, newline);
% % end
% % fp = fopen("P3_count_len.txt", "wt");
% % fprintf(fp, "%s", data);
% % fclose(fp);
% % 
% % 
% % data = "";
% % for i=1:length(P4(:,1))
% %     for j = 1:length(P4(1,:))
% %         data = append(data, num2str(P4(i,j)));
% %     end
% %     data = append(data, newline);
% % end
% % fp = fopen("P4_count_len.txt", "wt");
% % fprintf(fp, "%s", data);
% % fclose(fp);
% 
% 
% 
% % %====================================================================
% % %====================================================================
% % %====================================================================
% % %на оставшихся слотах делаю проверку того, что матрица P генерирует тот же
% % %LDPC довесок, что есть в сообщении
% % for i=641:1260
% %     data_check1(i-640,:) = demodqpsk(Slots(i,21:end));
% %     data_check2(i-640,:) = demodqpsk(Slots_pi2(i,21:end));
% %     data_check3(i-640,:) = demodqpsk(Slots_2pi2(i,21:end));
% %     data_check4(i-640,:) = demodqpsk(Slots_3pi2(i,21:end));
% % end
% % 
% % data_check1 = gf(data_check1); % перевод в поле Галуа
% % data_check2 = gf(data_check2);
% % data_check3 = gf(data_check3);
% % data_check4 = gf(data_check4);
% % P1 = gf(P1);
% % P2 = gf(P2);
% % P3 = gf(P3);
% % P4 = gf(P4);
% % 
% % counter1 = 0;
% % for i=1:length(data_check1(:,1))
% %     if ( data_check1(i,1:640)*P1 == data_check1(i,641:640+128+4)) %непосредственно сранение, что расчитал с помощью P и что передаётся в слотах
% %         counter1 = counter1 +1;
% %     else
% %         disp('error1')
% %     end
% % end
% % 
% % counter2 = 0;
% % for i=1:length(data_check2(:,1))
% %     if ( data_check2(i,1:640)*P2 == data_check2(i,641:640+128+4))
% %         counter2 = counter2 +1;
% %     else
% %         disp('error2')
% %     end
% % end
% % 
% % counter3 = 0;
% % for i=1:length(data_check3(:,1))
% %     if ( data_check3(i,1:640)*P3 == data_check3(i,641:640+128+4))
% %         counter3 = counter3 +1;
% %     else
% %         disp('error3')
% %     end
% % end
% % 
% % counter4 = 0;
% % for i=1:length(data_check4(:,1))
% %     if ( data_check4(i,1:640)*P4 == data_check4(i,641:640+128+4))
% %         counter4 = counter4 +1;
% %     else
% %         disp('error4')
% %     end
% % end
% % 
% % disp(counter1); 
% % disp(counter2); 
% % disp(counter3);
% % disp(counter4);




