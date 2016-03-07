databaseName = 'GpcsData';
databaseurl=strcat('jdbc:sqlserver://125.211.202.97:2866;');
driver='com.microsoft.sqlserver.jdbc.SQLServerDriver';
username='hit';
password='1994,,forever';
conn=database(databaseName, username, password, driver, databaseurl);
if(isempty(conn.URL))
    fprintf('数据库链接失败');
    exit
end
ping(conn);
str_list = 'select deviceId,workDate,case when subsoiling=1 and continuitySP=1 then 1 else 0 end flag from GpcsTest.dbo.tb_work where mtlbFlag=0';
curs_1 = exec(conn,str_list); 
setdbprefs('DataReturnFormat','structure'); 
curs_1=fetch(curs_1);
if(strcmp(curs_1.Data,'No Data')==1)
       return
end
if(strcmp(curs_1.Data,'0')==1)
       return
end
data_1 = curs_1.Data;
close(curs_1);
device_len = length(data_1.deviceId);
deviceNo = str2num(cell2mat(data_1.deviceId));
workDate = cell2mat(data_1.workDate);
on_off = data_1.flag;
number =0;
for i =1:1:device_len
%for i =1:1:1
    device_no = num2str(deviceNo(i));
    flag = on_off(i);
    final_time = workDate(i,:);
    databasename = strcat('GpcsData',final_time(3:4),final_time(6:7));
    flag1 = num2str(on_off(i));
    number= number+1;
    path = strcat('C:\Users\Administrator\Desktop\trail\',final_time);
    if ~exist(path)
      [s,mess,messid] = mkdir('C:\Users\Administrator\Desktop\trail\',final_time);
    end
    if(flag == 0)%关闭开关
        %32代表空格的ascii码
        str_1 = strcat('select longitude,latitude,speed,angle,deep2 from ',32,databasename,'.dbo.pointsDetail where deviceNo=',device_no,' ',' and flag=128 and gpsTime between ''',final_time, ' 00:00:00''', ' and ''',final_time,' 23:59:59''',' order by gpsTime');
        %curs=exec(conn, 'select longitude,latitude,speed,angle,deep2 from GpcsData1508.dbo.pointsDetail where deviceNo=31003 and flag=128 and gpsTime between ''2015-08-12 00:00:00'' and ''2015-08-12 23:59:59'' order by gpsTime');
        curs= exec(conn,str_1);
        setdbprefs('DataReturnFormat','numeric'); 
        curs=fetch(curs);
        if(strcmp(curs.Data,'No Data')==1)
             area = 0;
             area1 =0;
             area = num2str(area);
             area_1 = num2str(area1);
             str_0 = strcat('update GpcsTest.dbo.tb_work set mtlbFlag=1,areaMTLB1=',area,',','areaMTLB2=',area_1,32,'where deviceId=',device_no,32,'and workDate=''',final_time,'''');
             curs = exec(conn,str_0);
             close(curs);
             continue;
        end
        number= number+1;
        datacell = curs.Data;
        close(curs);
        num2 =datacell;
        C =[];
        v1 = num2(:,3);
        x=num2(:,1)/3600000;
        y=num2(:,2)/3600000;       
        title1 = strcat(device_no,'-',final_time,'轨迹图');
        figure(10)
        hold off;
        plot(x,y);
        axis equal;
        title(title1);
        guiji = strcat('C:\Users\Administrator\Desktop\trail\',final_time,'\',title1);
        print(10, '-dpng', guiji);
        index = find(num2(:,3) == 500);
        num2(index,:) = [];
        if(length(num2)<10)
             area = 0;
             area1 =0;
             area = num2str(area);
             area_1 = num2str(area1);
             str_0 = strcat('update GpcsTest.dbo.tb_work set mtlbFlag=1,areaMTLB1=',area,',','areaMTLB2=',area_1,32,'where deviceId=',device_no,32,'and workDate=''',final_time,'''');
             curs = exec(conn,str_0);
             close(curs);
             continue;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%转换成大地坐标
        lat = num2(:,2)/3600000;
        lon = num2(:,1)/3600000;
        % L=dlmread('position.txt');  % txt-style,your filename,data format-->latitude,longitude
        L = [lat lon];
        axesm utm;
        Z=utmzone(L(1,1),L(1,2));
        setm(gca,'zone',Z);
        h = getm(gca);
        R=zeros(size(L));
        for index=1:length(L)
        [long,latu]= mfwdtran(h,L(index,1),L(index,2));
        R(index,:)=[long;latu];
        end
        R = R/1000;
        x= R(:,1);
        y =R(:,2);
        %%%%%%%%%%%%%%%%%%%%%%%%
        Ld = length(x);
        ddf = zeros(Ld,1);
        if(length(num2)<1000)
            r = 0.15;
        else
            r =0.08;
        end
%         r = sqrt((range(x)/30)^2 + (range(y)/30)^2)
         for k=1:Ld
                    ddf(k) = sum( x>(x(k)-r) & x<(x(k)+r) & y>(y(k)-r) & y<(y(k)+r) );
         end
        area = (2*r)^2;
        ddf1 = ddf/area;
        %%%%%%%%%
        x1 = sort(ddf1);
        delta = [];
        for j=1:1:length(x1)-1
            d = x1(j+1)-x1(j);
            delta =[delta d];
        end
        delta1 = sort(delta);
        if(length(delta1)<10)
             jiexian1 =delta1(1:length(delta1));
        else
             jiexian1 =delta1(length(delta1)-9:length(delta1));
        end
         mode1 = mode(jiexian1);
         jiexian = 0;
       for index =1:length(jiexian1)
           if(jiexian1(index)>mode1)
               jiexian = jiexian1(index);
               break;
           end
       end
       if(jiexian ==0)
           jiexian = mode1;
       end
        max = 1;
        for j=1:1:length(delta)
            if(delta(j)>=jiexian)
                max = j;
                break;
            end
        end
        threshold1 = x1(max+1);
        if(threshold1>5000)
            threshold1 = 5000;
        elseif( threshold1<=1000)
                threshold1 = 1000;
        end
        count =0;
        for k=1:Ld
            if(ddf1(k)>threshold1)
                %num2(k,3)=500;
                count = count+1;
            end
        end
        if(count<100)
             area = 0;
             area1 =0;
             area = num2str(area);
             area_1 = num2str(area1);
             str_0 = strcat('update GpcsTest.dbo.tb_work set mtlbFlag=1,areaMTLB1=',area,',','areaMTLB2=',area_1,32,'where deviceId=',device_no,32,'and workDate=''',final_time,'''');
             curs = exec(conn,str_0);
             close(curs);
             continue;
        end
        for k=1:Ld
            if(ddf1(k)<threshold1)
                num2(k,3)=500;
            end
        end
        index = find(num2(:,3) == 500);
        num2(index,:) = [];
        if(length(num2)<100)
            x1 = 0;
            y1 = 0;
        else
            x1=num2(:,1)/3600000;
            y1=num2(:,2)/3600000;
        end  
        title2 = strcat(device_no,'-',final_time,'耕地轨迹');
        figure(2)
        hold off;
        plot(x1,y1,'.');
        title(title2);
        axis equal;
        gengdi = strcat('C:\Users\Administrator\Desktop\trail\',final_time,'\',title2);
        print(2, '-dpng', gengdi);
        %%%%%%%%%%%%%%%转换成大地坐标
        lat = num2(:,2)/3600000;
        lon = num2(:,1)/3600000;
        % L=dlmread('position.txt');  % txt-style,your filename,data format-->latitude,longitude
        L = [lat lon];
        axesm utm;
        Z=utmzone(L(1,1),L(1,2));
        setm(gca,'zone',Z);
        h = getm(gca);
        R=zeros(size(L));
        for index=1:length(L)
        [long,latu]= mfwdtran(h,L(index,1),L(index,2));
        R(index,:)=[long;latu];
        end
        R = R/1000;
        x1= R(:,1);
        y1 =R(:,2);
        %%%%%%%%%%%%%%%
        X = [x1 y1];
        [r,c] = size(X);
        if(r>2)
             figure(5)
             hold off;
             if(jiexian<=200)
                 area =alphavol(X,0.02,5);
             elseif(jiexian>200)
                area =alphavol(X,0.01,5);
             end
             area =num2str(area);
        else 
            area = num2str(0);
        end
          % str = strcat('insert into',32,databasename,'.dbo.area (date,deviceNo,area1,area2) values (''',final_time,''',',device_no,',''',area1,'''',',''',area1,''')');
          str = strcat('update GpcsTest.dbo.tb_work set mtlbFlag=1,areaMTLB1=',area,',','areaMTLB2=',area,32,'where deviceId=',device_no,32,'and workDate=''',final_time,'''');
          curs = exec(conn,str);
          close(curs);
        % % % % % % % figure(5)    
    else%打开开关
        str_1 = strcat('select longitude,latitude,speed,angle,deep2 from ',32,databasename,'.dbo.pointsDetail where deviceNo=',device_no,' ',' and flag=128 and gpsTime between ''',final_time, ' 00:00:00''', ' and ''',final_time,' 23:59:59''',' order by gpsTime');
        %curs=exec(conn, 'select longitude,latitude,speed,angle,deep2 from GpcsData1508.dbo.pointsDetail where deviceNo=31003 and flag=128 and gpsTime between ''2015-08-12 00:00:00'' and ''2015-08-12 23:59:59'' order by gpsTime');
        curs= exec(conn,str_1);
        setdbprefs('DataReturnFormat','numeric'); 
        curs=fetch(curs);
        if(strcmp(curs.Data,'No Data')==1)
            area = 0;
            area1 =0;
            area = num2str(area);
            area_1 = num2str(area1);
            str_0 = strcat('update GpcsTest.dbo.tb_work set mtlbFlag=1,areaMTLB1=',area,',','areaMTLB2=',area_1,32,'where deviceId=',device_no,32,'and workDate=''',final_time,'''');
            curs = exec(conn,str_0);
            close(curs);
            continue;
        end
        number= number+1;
        datacell = curs.Data;
        close(curs);
        num2 =datacell;
        C =[];
        v1 = num2(:,3);
        x=num2(:,1)/3600000;
        y=num2(:,2)/3600000;       
        title1 = strcat(device_no,'-',final_time,'轨迹图');
        figure(10)
        hold off;
        plot(x,y);
        axis equal;
        title(title1);
        guiji = strcat('C:\Users\Administrator\Desktop\trail\',final_time,'\',title1);
        print(10, '-dpng', guiji);
        index = find(num2(:,3) == 500);
        num2(index,:) = [];
        if(length(num2)<10)
             area = 0;
             area1 =0;
             area = num2str(area);
             area_1 = num2str(area1);
             str_0 = strcat('update GpcsTest.dbo.tb_work set mtlbFlag=1,areaMTLB1=',area,',','areaMTLB2=',area_1,32,'where deviceId=',device_no,32,'and workDate=''',final_time,'''');
             curs = exec(conn,str_0);
             close(curs);
             continue;
        end
      
        %%%%%%%%%%%%%%%%%%%%%%%%转换成大地坐标
        lat = num2(:,2)/3600000;
        lon = num2(:,1)/3600000;
        % L=dlmread('position.txt');  % txt-style,your filename,data format-->latitude,longitude
        L = [lat lon];
        axesm utm;
        Z=utmzone(L(1,1),L(1,2));
        setm(gca,'zone',Z);
        h = getm(gca);
        R=zeros(size(L));
        for index=1:length(L)
        [long,latu]= mfwdtran(h,L(index,1),L(index,2));
        R(index,:)=[long;latu];
        end
        R = R/1000;
        x= R(:,1);
        y =R(:,2);
        %%%%%%%%%%%%%%%%%%%%%%%%
        Ld = length(x);
        ddf = zeros(Ld,1);
        if(length(num2)<1000)
            r = 0.15;
        else
            r =0.08;
        end
%         r = sqrt((range(x)/30)^2 + (range(y)/30)^2)
         for k=1:Ld
                    ddf(k) = sum( x>(x(k)-r) & x<(x(k)+r) & y>(y(k)-r) & y<(y(k)+r) );
         end
        area = (2*r)^2;
        ddf1 = ddf/area;
        %%%%%%%%%
        x1 = sort(ddf1);
        delta = [];
        for j=1:1:length(x1)-1
            d = x1(j+1)-x1(j);
            delta =[delta d];
        end
        delta1 = sort(delta);
        if(length(delta1)<10)
             jiexian1 =delta1(1:length(delta1));
        else
             jiexian1 =delta1(length(delta1)-9:length(delta1));
        end
        mode1 = mode(jiexian1);
        jiexian = 0;
        for index =1:length(jiexian1)
            if(jiexian1(index)>mode1)
                jiexian = jiexian1(index);
                break;
            end
        end
        if(jiexian ==0)
            jiexian = mode1;
        end
        max = 1;
        for j=1:1:length(delta)
            if(delta(j)>=jiexian)
                max = j;
                break;
            end
        end
        threshold1 = x1(max+1);
%           threshold1 = threshold1*1.5;
        if(threshold1>5000)
            threshold1 = 5000;
        elseif( threshold1<=1000)
                threshold1 = 1000;
        end
        %%%%%%%%%%%%%
        count =0;
        for k=1:Ld
            if(ddf1(k)>threshold1)
                %num2(k,3)=500;
                count = count+1;
            end
        end
        if(count<100)
            area = 0;
            area1 =0;
            area = num2str(area);
            area_1 = num2str(area1);
            str_0 = strcat('update GpcsTest.dbo.tb_work set mtlbFlag=1,areaMTLB1=',area,',','areaMTLB2=',area_1,32,'where deviceId=',device_no,32,'and workDate=''',final_time,'''');
            curs = exec(conn,str_0);
            close(curs);
            continue;
        end
        for k=1:Ld
            if(ddf1(k)<threshold1)
                num2(k,3)=500;
            end
        end
        index = find(num2(:,3) == 500);
        num2(index,:) = [];
        if(length(num2)<100)
            x1 = 0;
            y1 = 0;
        else
            x1=num2(:,1)/3600000;
            y1=num2(:,2)/3600000;
        end  
        title2 = strcat(device_no,'-',final_time,'耕地轨迹');
        figure(2)
        hold off;
        plot(x1,y1,'.');
        title(title2);
        axis equal;
        gengdi = strcat('C:\Users\Administrator\Desktop\trail\',final_time,'\',title2);
        print(2, '-dpng', gengdi);
        %%%%%%%%%%%%%%%转换成大地坐标
        lat = num2(:,2)/3600000;
        lon = num2(:,1)/3600000;
        % L=dlmread('position.txt');  % txt-style,your filename,data format-->latitude,longitude
        L = [lat lon];
        axesm utm;
        Z=utmzone(L(1,1),L(1,2));
        setm(gca,'zone',Z);
        h = getm(gca);
        R=zeros(size(L));
        for index=1:length(L)
        [long,latu]= mfwdtran(h,L(index,1),L(index,2));
        R(index,:)=[long;latu];
        end
        R = R/1000;
        x1= R(:,1);
        y1 =R(:,2);
        %%%%%%%%%%%%%%%
        X = [x1 y1];
        [r,c] = size(X);
        if(r>2)
             figure(5)
             hold off;
             if(jiexian<=200)
                 area =alphavol(X,0.02,5);
             elseif(jiexian>200)
                area =alphavol(X,0.01,5);
             end
             area =num2str(area);
        else 
            area = num2str(0);
        end
        % % % % % % % figure(5)
        str_0 = strcat('select count(*) from ',32,databasename,'.dbo.pointsDetail where deviceNo=',device_no,' ',' and flag=128 and gpsTime between ''',final_time, ' 00:00:00''', ' and ''',final_time,' 23:59:59''','and deep2 between 15 and 70');
        %curs=exec(conn, 'select longitude,latitude,speed,angle,deep2 from GpcsData1508.dbo.pointsDetail where deviceNo=31003 and flag=128 and gpsTime between ''2015-08-12 00:00:00'' and ''2015-08-12 23:59:59'' order by gpsTime');
        curs_0= exec(conn,str_0);
        setdbprefs('DataReturnFormat','numeric'); 
        curs_0=fetch(curs_0);
        area_1 = num2str(0);
        if(curs_0.Data>100)              
            str_2 = strcat('select longitude,latitude,speed,angle,deep2 from ',32,databasename,'.dbo.pointsDetail where deviceNo=',device_no,' ',' and flag=128 and deep2 between 15 and 70 and gpsTime between ''',final_time, ' 00:00:00''', ' and ''',final_time,' 23:59:59''',' order by gpsTime');
            %curs=exec(conn, 'select longitude,latitude,speed,angle,deep2 from GpcsData1508.dbo.pointsDetail where deviceNo=31003 and flag=128 and gpsTime between ''2015-08-12 00:00:00'' and ''2015-08-12 23:59:59'' order by gpsTime');
            curs= exec(conn,str_2);
            setdbprefs('DataReturnFormat','numeric'); 
            curs=fetch(curs);
            if(strcmp(curs.Data,'No Data')==1)
                 area = 0;
                 area1 =0;
                 area = num2str(area);
                 area_1 = num2str(area1);
                 str_0 = strcat('update GpcsTest.dbo.tb_work set mtlbFlag=1,areaMTLB1=',area,',','areaMTLB2=',area_1,32,'where deviceId=',device_no,32,'and workDate=''',final_time,'''');
                 curs = exec(conn,str_0);
                 close(curs);
                 continue;
            end
            datacell_1 = curs.Data;
            close(curs);
            num3 =datacell_1;
            index = find(num3(:,3) == 500);
            num3(index,:) = [];
            x1=num3(:,1)/3600000;
            y1=num3(:,2)/3600000;
            %%%%%%%%%%%%%%%转换成大地坐标
            lat = num3(:,2)/3600000;
            lon = num3(:,1)/3600000;
            % L=dlmread('position.txt');  % txt-style,your filename,data format-->latitude,longitude
            L = [lat lon];
            axesm utm;
            Z=utmzone(L(1,1),L(1,2));
            setm(gca,'zone',Z);
            h = getm(gca);
            R=zeros(size(L));
            for index=1:length(L)
            [long,latu]= mfwdtran(h,L(index,1),L(index,2));
            R(index,:)=[long;latu];
            end
            R = R/1000;
            x2= R(:,1);
            y2 =R(:,2);
            %带有传感器的机器的聚合图
            %         title3 = strcat(device_no,'-',final_time,'聚合图');
            %         figure(11)
            %         hold off;
            %         plot(x,y,'.');
            %         axis equal;
            %         title(title3);
            %         juhe = strcat('C:\Users\Administrator\Desktop\trail\',folderName,'\',title3);
            %         print(11, '-dpng', juhe);
            %%%%%%%%%%%%%%%
            X = [x2 y2];
            figure(6)
            hold off;
            if(length(x2)<1000)
                area_0 =alphavol(X,0.02,6);
            else
                area_0 = alphavol(X,0.01,6);
            end
               area_1 =num2str(area_0);
           
            % % % % % % % figure(5)          
        end
         str_0 = strcat('update GpcsTest.dbo.tb_twork set mtlbFlag=1,areaMTLB1=',area,',','areaMTLB2=',area_1,32,'where deviceId=',device_no,32,'and workDate=''',final_time,'''');
         curs = exec(conn,str_0);
         close(curs);
    end
end
cur_2 = exec(conn,'GpcsTest.dbo.synWorkDay');
% colse(cur_2);
close(conn);
%  exit