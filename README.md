# backup.sh
From teddysun

1.容器化
2.仅支持备份到FTP
3.去除了rclone和mysql备份功能
4.去除了tar参数 -P

    docker run -d \
      --name=backup \
      -v "path to backup":/backup \
      --restart always \
      ju0594/backup.sh
	  
"path to backup" 选个主机上的目录映射

定时任务
映射目录/crontabs/root

备份参数
映射目录/backup.sh

参考 https://teddysun.com/469.html

备份文件的解密命令如下：

openssl enc -aes256 -in [ENCRYPTED BACKUP] -out decrypted_backup.tgz -pass pass:[BACKUPPASS] -d -md sha1

备份文件解密后，解压命令如下：

tar -zxf [DECRYPTION BACKUP FILE]

解释一下为什么去除参数 -P：
tar 压缩文件默认都是相对路径的。加个 -P 是为了 tar 能以绝对路径压缩文件。因此，解压的时候也要带个 -P 参数。
但是Alpine带的tar不支持-p命令，所以去除了，解压的时候自己注意下路径就行。