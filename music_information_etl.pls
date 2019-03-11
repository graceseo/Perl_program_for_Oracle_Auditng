CREATE OR REPLACE PACKAGE unimeta_util as

  PROCEDURE universal_apply_meta;
  PROCEDURE universal_manual_meta(P_ALBUM_ID NUMBER);

end unimeta_util;
/

CREATE OR REPLACE PACKAGE BODY unimeta_util
AS
PROCEDURE universal_apply_meta
IS
        m_sql VARCHAR2(1000);
BEGIN
        --TRACK_GROUP
        --#### 2011.1.13. ###--------
        BEGIN
                MERGE INTO track_group a USING
                (SELECT TRACK_GROUP_ID,
                        TRACK_GROUP_TITLE,
                        TRACK_GROUP_KOR_TITLE,
                        ALBUM_ID,
                        CRT_DT,
                        DB_STS
                FROM    track_group@cfeel
                WHERE crt_dt > trunc(SYSDATE -1) OR upd_dt > trunc(SYSDATE -1)
                ) b ON (a.TRACK_GROUP_ID=b.TRACK_GROUP_ID)
        WHEN MATCHED THEN
                UPDATE
                SET a.TRACK_GROUP_TITLE    =b.TRACK_GROUP_TITLE,
                        a.TRACK_GROUP_KOR_TITLE=b.TRACK_GROUP_KOR_TITLE,
                        a.ALBUM_ID=b.ALBUM_ID,
                        a.CRT_DT =sysdate ,
                        a.DB_STS=b.DB_STS
                        WHEN NOT MATCHED THEN
                INSERT
                        (
                                TRACK_GROUP_ID,
                                TRACK_GROUP_TITLE,
                                TRACK_GROUP_KOR_TITLE,
                                ALBUM_ID,
                                CRT_DT,
                                DB_STS
                        )
                        VALUES
                        (
                                b.TRACK_GROUP_ID,
                                b.TRACK_GROUP_TITLE,
                                b.TRACK_GROUP_KOR_TITLE,
                                b.ALBUM_ID,
                                sysdate,
                                b.DB_STS
                        );
                COMMIT;
        END;
        --MUSIC
        --벅스서비스는 유니버셜인 경우 flac_yn이 무조건 'N'이나 유니버셜에 나갈땐 flac_yn을 ted_track에 있는대로 내보낸다.
        BEGIN
                m_sql := 'truncate table   UNI_MUSIC';
                EXECUTE IMMEDIATE m_sql;
                --트랙의 artist는 대표 artist만 넣는다.
                INSERT INTO /*+ append */
                        UNI_MUSIC
                SELECT  t1.MEDIA_NO,
                        t1.TRACK_ID,
                        t1.TRACK_TITLE,
                        t1.TRACK_NO,
                        t1.TITLE_YN,
                        t1.LEN,
                        t1.DISC_ID,
                        t1.LYRICS_TP,
                        t1.ARTIST_ID,
                        t1.ARTIST_NM,
                        t1.ALBUM_ID,
                        t1.ALBUM_TITLE,
                        t1.ALBUM_ARTIST_ID,
                        t1.ALBUM_ARTIST_NM,
                        t1.RELEASE_YMD,
                        t1.MV_ID,
                        t1.HIGHRATE_YN,
                        t1.NATION_CD,
                        t1.GENRE_CD,
                        t1.ADULT_YN,
                        t1.AMP3_YN,
                        t1.SVC_128_YN,
                        t1.SVC_192_YN,
                        t1.SVC_320_YN,
                        t1.STR_RIGHTS_YN,
                        t1.DNL_RIGHTS_YN,
                        t1.MV_STR_YN,
                        t1.CRT_DT,
                        t1.upd_dt,
                        t1.DB_STS,
                        t1.AGENCY_ID,
                        t1.AGENCY_NM,
                        t1.GENRE_DTL,
                        t1.LIVEBELL_YN,
                        t1.SVC_FULLHD_YN,
                        t1.SVC_HD_YN,
                        t1.SVC_SD_YN,
                        t1.SVC_MP4_YN,
                       Nvl((CASE WHEN t3.MEDIA_YN = 'Y' THEN t3.SVC_FLAC_YN ELSE 'N' END),'N') as SVC_FLAC_YN ,
                        t1.FULLHD_PRICE,
                        t1.HD_PRICE,
                        t1.SD_PRICE,
                        t3.track_group_id,
                        t1.search_title
                FROM    tmu_music@bugsmeta t1,
                        (select distinct track_id
                        from track_use_map@mcms t4,
                            --20110712 아래 뷰는 최상위 계약을 찾아낸다--
                           (select use_cont_id,company_id, connect_by_root use_cont_id root_id
                            from use_cont@mcms
                            start with pre_use_cont_id is null
                            connect by pre_use_cont_id=prior use_cont_id
                           ) t5
                           --!!!!!!!!!! 아래 반드시 계약번호 변경!!!!1--
                        where t4.use_cont_id=t5.use_cont_id and  t5.company_id IN (2090) and (SYSDATE BETWEEN t4.start_dt AND NVL(t4.end_dt, SYSDATE)) and t5.root_id!=20963 and t5.root_id!=22606
                        ) t2,
                        ted_track@cfeel t3
                WHERE   t1.track_id      =t2.track_id
                    AND t1.track_id      =t3.track_id;

                --클래식 agency_id는 따로 넣는다. flac발급이 안되있으면 아예 메타가 나가지 않는다.
                 INSERT INTO /*+ append */
                        UNI_MUSIC
                SELECT  t1.MEDIA_NO,
                        t1.TRACK_ID,
                        t1.TRACK_TITLE,
                        t1.TRACK_NO,
                        t1.TITLE_YN,
                        t1.LEN,
                        t1.DISC_ID,
                        t1.LYRICS_TP,
                        t1.ARTIST_ID,
                        t1.ARTIST_NM,
                        t1.ALBUM_ID,
                        t1.ALBUM_TITLE,
                        t1.ALBUM_ARTIST_ID,
                        t1.ALBUM_ARTIST_NM,
                        t1.RELEASE_YMD,
                        t1.MV_ID,
                        t1.HIGHRATE_YN,
                        t1.NATION_CD,
                        t1.GENRE_CD,
                        t1.ADULT_YN,
                        t1.AMP3_YN,
                        t1.SVC_128_YN,
                        t1.SVC_192_YN,
                        t1.SVC_320_YN,
                        'Y' as STR_RIGHTS_YN,
                        'Y' as DNL_RIGHTS_YN,
                        t1.MV_STR_YN,
                        t1.CRT_DT,
                        t1.upd_dt,
                        t1.DB_STS,
                        t1.AGENCY_ID,
                        t1.AGENCY_NM,
                        t1.GENRE_DTL,
                        t1.LIVEBELL_YN,
                        t1.SVC_FULLHD_YN,
                        t1.SVC_HD_YN,
                        t1.SVC_SD_YN,
                        t1.SVC_MP4_YN,
                       Nvl((CASE WHEN t3.MEDIA_YN = 'Y' THEN t3.SVC_FLAC_YN ELSE 'N' END),'N') as SVC_FLAC_YN ,
                        t1.FULLHD_PRICE,
                        t1.HD_PRICE,
                        t1.SD_PRICE,
                        t3.track_group_id,
                        t1.search_title
                FROM    tmu_music@bugsmeta t1,
                        (select distinct track_id
                        from track_use_map@mcms t4,
                            --20110712 아래 뷰는 최상위 계약을 찾아낸다--
                           (select use_cont_id,company_id, connect_by_root use_cont_id root_id
                            from use_cont@mcms
                            start with pre_use_cont_id is null
                            connect by pre_use_cont_id=prior use_cont_id
                           ) t5
                           --!!!!!!!!!! 아래 반드시 계약번호 변경!!!!1--
                        where t4.use_cont_id=t5.use_cont_id and  t5.company_id IN (2090) and (SYSDATE BETWEEN t4.start_dt AND NVL(t4.end_dt, SYSDATE)) and t5.root_id=20963
                        ) t2,
                        ted_track@cfeel t3
                WHERE   t1.track_id      =t2.track_id
                    AND t1.track_id      =t3.track_id
                    and t3.svc_flac_yn='Y';

                    ---2011.5.23. 강제반영되는 트랙id만을 위한 부분--
                --2011.5.23. 뮤비를 위한 특정트랙만 등록해야할때 사용한다.
                --tecs_rights@mcms테이블에서 agent번호를 확인후 적용해야 하나 가상앨범은 agent정보가 없다고 보므로 이부분을 뺀다.
                 INSERT INTO /*+ append */
                        UNI_MUSIC
                SELECT  t1.MEDIA_NO,
                        t1.TRACK_ID,
                        t1.TRACK_TITLE,
                        t1.TRACK_NO,
                        t1.TITLE_YN,
                        t1.LEN,
                        t1.DISC_ID,
                        t1.LYRICS_TP,
                        t1.ARTIST_ID,
                        t1.ARTIST_NM,
                        t1.ALBUM_ID,
                        t1.ALBUM_TITLE,
                        t1.ALBUM_ARTIST_ID,
                        t1.ALBUM_ARTIST_NM,
                        t1.RELEASE_YMD,
                        t1.MV_ID,
                        t1.HIGHRATE_YN,
                        t1.NATION_CD,
                        t1.GENRE_CD,
                        t1.ADULT_YN,
                        t1.AMP3_YN,
                        t1.SVC_128_YN,
                        t1.SVC_192_YN,
                        t1.SVC_320_YN,
                        --2011.5.23. 다운로드 및 스트리밍은 불가상태로 만든다,--
                        'N' as STR_RIGHTS_YN,
                        'N' as DNL_RIGHTS_YN,
                        t1.MV_STR_YN,
                        t1.CRT_DT,
                        t1.upd_dt,
                        t1.DB_STS,
                        t1.AGENCY_ID,
                        t1.AGENCY_NM,
                        t1.GENRE_DTL,
                        t1.LIVEBELL_YN,
                        t1.SVC_FULLHD_YN,
                        t1.SVC_HD_YN,
                        t1.SVC_SD_YN,
                        t1.SVC_MP4_YN,
                       'N' as  SVC_FLAC_YN ,
                        t1.FULLHD_PRICE,
                        t1.HD_PRICE,
                        t1.SD_PRICE,
                        t3.track_group_id,
                        t1.search_title
                FROM    tmu_music@bugsmeta t1,
                        ted_track@cfeel t3
                WHERE  t1.track_id    =t3.track_id
                    and t1.album_id in  (289600);

                COMMIT;
        END;
        --ALBUM
        BEGIN
                m_sql := 'truncate  table UNI_ALBUM';
                EXECUTE IMMEDIATE m_sql;
                INSERT INTO UNI_ALBUM
                SELECT  t1.ALBUM_ID,
                        t1.TITLE,
                        t1.SEARCH_TITLE,
                        t1.ARTIST_ID,
                        t1.ARTIST_NM,
                        t1.GENRE_CD,
                        t1.NATION_CD,
                        t1.AGENCY_ID,
                        t1.AGENCY_NM,
                        t1.RELEASE_YMD,
                        t1.KEYWORD,
                        t1.ALBUM_TP,
                        t1.CRT_DT,
                        t1.UPD_DT,
                        t1.DISK_CNT,
                        t1.DB_STS
                FROM    tmu_album@bugsmeta t1
                WHERE   EXISTS
                        (SELECT 1 FROM UNI_MUSIC t2 WHERE t1.album_id=t2.album_id
                        );
        END;
        --ARTIST
        BEGIN
                --uni_music은 유니버셜 전용 track만 이므로 uni_music테이블과 trackartist를 조인해서   이 트랙관련 artist만 가져온다.
                m_sql := 'truncate  table  UNI_ARTIST';
                EXECUTE IMMEDIATE m_sql;
                INSERT INTO UNI_ARTIST
                SELECT  t1.ARTIST_ID,
                        t1.ARTIST_NM,
                        t1.DISP_NM,
                        t1.KOR_NM,
                        t1.SRCH_NM,
                        t1.BIRTH_YMD,
                        t1.NATION_CD,
                        t1.GENRE_CD,
                        t1.GRP_CD,
                        t1.SEX_CD,
                        t1.HOMEPAGE_URL,
                        t1.ACT_START_YMD,
                        t1.ACT_END_YMD,
                        t1.CRT_DT,
                        t1.UPD_DT,
                        t1.DB_STS
                FROM    tmu_artist@bugsmeta t1
                WHERE   EXISTS
                        (SELECT 1
                        FROM    UNI_MUSIC t2,
                                cfeel.ted_trackartist@cfeel t3
                        WHERE   t1.artist_id=t3.artist_id
                            AND t2.track_id =t3.track_id
                            AND t3.db_sts   ='A'
                        );
        END;
        --MV
        BEGIN
                m_sql := 'truncate  table   UNI_MV';
                EXECUTE IMMEDIATE m_sql;
                INSERT INTO UNI_MV
                SELECT  t1.MV_ID,
                        t1.MV_TITLE,
                        t1.TRACK_ID,
                        t1.TRACK_TITLE,
                        t1.ARTIST_ID,
                        t1.ARTIST_NM,
                        t1.ALBUM_ID,
                        t1.NATION_CD,
                        t1.ALBUM_TITLE,
                        t1.HIGHRATE_YN,
                        t1.ACTOR,
                        t1.DSCR,
                        t1.RELEASE_YMD,
                        t1.CRT_DT,
                        t1.UPD_DT,
                        t1.DB_STS,
                        t1.SVC_FULLHD_YN,
                        t1.SVC_HD_YN,
                        t1.SVC_SD_YN,
                        t1.SVC_MP4_YN,
                        t1.MEDIA_NO,
                        decode(album_id,289600,'Y',t1.SVC_STR_YN) as svc_str_yn,
                        t1.attr_tp,
                        t1.FULLHD_PRICE,
                        t1.HD_PRICE,
                        t1.SD_PRICE
                FROM    tmu_mv@bugsmeta t1
                WHERE   EXISTS
                        (SELECT 1 FROM UNI_MUSIC t2 WHERE t1.track_id=t2.track_id
                        );
        END;
        --TRACKSTYLE
        BEGIN
                m_sql :='truncate  table  UNI_TRACKSTYLE';
                EXECUTE IMMEDIATE m_sql;
                INSERT INTO UNI_TRACKSTYLE
                SELECT  track_id,
                        style_id,
                        listorder,
                        crt_dt
                FROM    TBM_TRACKSTYLE@bugsmeta t1
                WHERE   EXISTS
                        (SELECT 1 FROM UNI_MUSIC t2 WHERE t1.track_id=t2.track_id
                        );
        END;
        --ALBUM_PHOTO
        BEGIN
                m_sql :='truncate  table   UNI_ALBUM_PHOTO';
                EXECUTE IMMEDIATE m_sql;
                INSERT INTO uni_album_photo
                SELECT  album_id,
                        album_photo_id,
                        image,
                        repres_yn,
                        priority,
                        regdate
                FROM    album_photo@bugsmeta t1
                WHERE   EXISTS
                        (SELECT 1 FROM uni_album t2 WHERE t1.album_id=t2.album_id
                        );
        END;
        --ARTIST_PHOTO
        BEGIN
                m_sql :='truncate  table   UNI_ARTIST_PHOTO';
                EXECUTE IMMEDIATE m_sql;
                INSERT INTO uni_artist_photo
                SELECT  artist_id,
                        artist_photo_id,
                        image,
                        repres_yn,
                        priority,
                        regdate
                FROM    artist_photo@bugsmeta t1
                WHERE   EXISTS
                        (SELECT 1 FROM uni_artist t2 WHERE t1.artist_id=t2.artist_id
                        );
        END;
        --codedtl
        BEGIN
                MERGE INTO codedtl a USING
                (SELECT cd_dtl_cd,
                        cd_id,
                        cd_dtl_nm,
                        cd_dtl_exp,
                        prir_seq,
                        crt_dt,
                        upd_id,
                        db_sts
                FROM    tfm_codedtl@cfeel
                ) b ON (a.cd_dtl_cd=b.cd_dtl_cd AND a.cd_id=b.cd_id)
        WHEN MATCHED THEN
                UPDATE
                SET     a.cd_dtl_nm = b.cd_dtl_nm,
                        a.cd_dtl_exp=b.cd_dtl_exp,
                        a.prir_seq  =b.prir_seq,
                        a.crt_dt    =b.crt_dt,
                        a.upd_id    =b.upd_id,
                        a.db_sts    =b.db_sts WHEN NOT MATCHED THEN
                INSERT
                        (
                                cd_dtl_cd,
                                cd_id,
                                cd_dtl_nm,
                                cd_dtl_exp,
                                prir_seq,
                                crt_dt,
                                upd_id,
                                db_sts
                        )
                        VALUES
                        (
                                b.cd_dtl_cd,
                                b.cd_id,
                                b.cd_dtl_nm,
                                b.cd_dtl_exp,
                                b.prir_seq,
                                b.crt_dt,
                                b.upd_id,
                                b.db_sts
                        );
        END;
        --TRACKARTIST
        BEGIN
                --#### 2011.1.13. 추가 ###--------
                --대표아티스므만 순번이 0이고 나머지는 전부 1이다.
                m_sql :='truncate table  uni_trackartist';
                EXECUTE IMMEDIATE m_sql;
                INSERT INTO uni_trackartist
                SELECT  a.TRACKARTIST_ID ,
                        a.ARTIST_ID,
                        a.TRACK_ID,
                        a.RP_CD,
                        DECODE(a.rp_cd,'Y',0,1) AS ARTIST_PRIOR,
                        b.cd_id,
                        b.cd_dtl_cd,
                        a.crt_dt
                FROM    ted_trackartist@cfeel a ,
                        codedtl b
                WHERE   EXISTS
                        (SELECT 1 FROM uni_music c WHERE a.track_id=c.track_id
                        )
                    AND a.role_cd=b.cd_dtl_cd
                    AND b.cd_id  =22
                    AND a.db_sts ='A';
        END;

        --GENRE
        BEGIN
                MERGE INTO genre a USING
                ( SELECT genre_cd, genre_nm FROM tmu_genre@cfeel WHERE genre_cd = pgenre_cd
                ) b ON (a.genre_id = b.genre_cd)
        WHEN MATCHED THEN
                UPDATE SET a.genre_nm = b.genre_nm WHEN NOT MATCHED THEN
                INSERT
                        (
                                genre_id,
                                genre_nm,
                                crt_dt
                        )
                        VALUES
                        (
                                b.genre_cd,
                                b.genre_nm,
                                sysdate
                        );
        END;
        --STYLE
        BEGIN
                MERGE INTO style a USING
                (SELECT genre_cd,
                                pgenre_cd,
                                genre_nm
                        FROM    tmu_genre@cfeel aa
                        WHERE   genre_cd != pgenre_cd
                            AND EXISTS
                                (SELECT 1 FROM genre bb WHERE aa.genre_cd = bb.genre_id
                                )
                )
                b ON (a.style_id = b.pgenre_cd)
        WHEN MATCHED THEN
                UPDATE SET a.style_nm = b.genre_nm WHEN NOT MATCHED THEN
                INSERT
                        (
                                style_id,
                                genre_id,
                                style_nm,
                                crt_dt
                        )
                        VALUES
                        (
                                b.pgenre_cd,
                                b.genre_cd,
                                b.genre_nm,
                                sysdate
                        );
        END ;
        COMMIT;
END universal_apply_meta;

PROCEDURE universal_manual_meta(P_ALBUM_ID NUMBER)
IS
        m_sql VARCHAR2(1000);
BEGIN
        --TRACK_GROUP
        --2011.5..23. colasarang 유니버셜 수동반영
        BEGIN
                MERGE INTO track_group a USING
                (SELECT TRACK_GROUP_ID,
                        TRACK_GROUP_TITLE,
                        TRACK_GROUP_KOR_TITLE,
                        ALBUM_ID,
                        CRT_DT,
                        DB_STS
                FROM    track_group@cfeel
                WHERE crt_dt > trunc(SYSDATE -1) OR upd_dt > trunc(SYSDATE -1)
                ) b ON (a.TRACK_GROUP_ID=b.TRACK_GROUP_ID)
        WHEN MATCHED THEN
                UPDATE
                SET a.TRACK_GROUP_TITLE    =b.TRACK_GROUP_TITLE,
                        a.TRACK_GROUP_KOR_TITLE=b.TRACK_GROUP_KOR_TITLE,
                        a.ALBUM_ID=b.ALBUM_ID,
                        a.CRT_DT =sysdate ,
                        a.DB_STS=b.DB_STS
                        WHEN NOT MATCHED THEN
                INSERT
                        (
                                TRACK_GROUP_ID,
                                TRACK_GROUP_TITLE,
                                TRACK_GROUP_KOR_TITLE,
                                ALBUM_ID,
                                CRT_DT,
                                DB_STS
                        )
                        VALUES
                        (
                                b.TRACK_GROUP_ID,
                                b.TRACK_GROUP_TITLE,
                                b.TRACK_GROUP_KOR_TITLE,
                                b.ALBUM_ID,
                                sysdate,
                                b.DB_STS
                        );
                COMMIT;
        END;
        --MUSIC
        --벅스서비스는 유니버셜인 경우 flac_yn이 무조건 'N'이나 유니버셜에 나갈땐 flac_yn을 ted_track에 있는대로 내보낸다.
        --수동의 경우 유니버셜음원이었다가 아닌 경우는 아예 삭제 되어야 하므로 delete후 insert로 한다.
        BEGIN
        ---4대 메타는 수동은 해당 앨범의 경우 모두 delete하는 것으로 한다.
                                --2011.5.23. 수동용 추가--
                delete from UNI_MUSIC where album_id=P_ALBUM_ID;

                --트랙의 artist는 대표 artist만 넣는다.
                INSERT INTO /*+ append */
                        UNI_MUSIC
                SELECT  t1.MEDIA_NO,
                        t1.TRACK_ID,
                        t1.TRACK_TITLE,
                        t1.TRACK_NO,
                        t1.TITLE_YN,
                        t1.LEN,
                        t1.DISC_ID,
                        t1.LYRICS_TP,
                        t1.ARTIST_ID,
                        t1.ARTIST_NM,
                        t1.ALBUM_ID,
                        t1.ALBUM_TITLE,
                        t1.ALBUM_ARTIST_ID,
                        t1.ALBUM_ARTIST_NM,
                        t1.RELEASE_YMD,
                        t1.MV_ID,
                        t1.HIGHRATE_YN,
                        t1.NATION_CD,
                        t1.GENRE_CD,
                        t1.ADULT_YN,
                        t1.AMP3_YN,
                        t1.SVC_128_YN,
                        t1.SVC_192_YN,
                        t1.SVC_320_YN,
                        t1.STR_RIGHTS_YN,
                        t1.DNL_RIGHTS_YN,
                        t1.MV_STR_YN,
                        t1.CRT_DT,
                        to_char(sysdate,'yyyymmddhh24miss'),
                        t1.DB_STS,
                        t1.AGENCY_ID,
                        t1.AGENCY_NM,
                        t1.GENRE_DTL,
                        t1.LIVEBELL_YN,
                        t1.SVC_FULLHD_YN,
                        t1.SVC_HD_YN,
                        t1.SVC_SD_YN,
                        t1.SVC_MP4_YN,
                       Nvl((CASE WHEN t3.MEDIA_YN = 'Y' THEN t3.SVC_FLAC_YN ELSE 'N' END),'N') as SVC_FLAC_YN ,
                        t1.FULLHD_PRICE,
                        t1.HD_PRICE,
                        t1.SD_PRICE,
                        t3.track_group_id,
                        t1.search_title
                FROM    tmu_music@bugsmeta t1,
                        (select distinct track_id
                        from track_use_map@mcms t4,
                            --20110712 아래 뷰는 최상위 계약을 찾아낸다--
                           (select use_cont_id,company_id, connect_by_root use_cont_id root_id
                            from use_cont@mcms
                            start with pre_use_cont_id is null
                            connect by pre_use_cont_id=prior use_cont_id
                           ) t5
                           --!!!!!!!!!! 아래 반드시 계약번호 변경!!!!1--
                        where t4.use_cont_id=t5.use_cont_id and  t5.company_id IN (2090) and (SYSDATE BETWEEN t4.start_dt AND NVL(t4.end_dt, SYSDATE)) and t5.root_id!=20963  and t5.root_id!=22606
                        ) t2,
                        ted_track@cfeel t3
                WHERE   t1.track_id      =t2.track_id
                    AND t1.track_id      =t3.track_id
                    --2011.5.23. 수동전용 추가
                    and t1.album_id=P_ALBUM_ID;

                --클래식 agency_id는 따로 넣는다. flac발급이 안되있으면 아예 메타가 나가지 않는다.
                 INSERT INTO /*+ append */
                        UNI_MUSIC
                SELECT  t1.MEDIA_NO,
                        t1.TRACK_ID,
                        t1.TRACK_TITLE,
                        t1.TRACK_NO,
                        t1.TITLE_YN,
                        t1.LEN,
                        t1.DISC_ID,
                        t1.LYRICS_TP,
                        t1.ARTIST_ID,
                        t1.ARTIST_NM,
                        t1.ALBUM_ID,
                        t1.ALBUM_TITLE,
                        t1.ALBUM_ARTIST_ID,
                        t1.ALBUM_ARTIST_NM,
                        t1.RELEASE_YMD,
                        t1.MV_ID,
                        t1.HIGHRATE_YN,
                        t1.NATION_CD,
                        t1.GENRE_CD,
                        t1.ADULT_YN,
                        t1.AMP3_YN,
                        t1.SVC_128_YN,
                        t1.SVC_192_YN,
                        t1.SVC_320_YN,
                        'Y' as STR_RIGHTS_YN,
                        'Y' as DNL_RIGHTS_YN,
                        t1.MV_STR_YN,
                        t1.CRT_DT,
                        to_char(sysdate,'yyyymmddhh24miss'),
                        t1.DB_STS,
                        t1.AGENCY_ID,
                        t1.AGENCY_NM,
                        t1.GENRE_DTL,
                        t1.LIVEBELL_YN,
                        t1.SVC_FULLHD_YN,
                        t1.SVC_HD_YN,
                        t1.SVC_SD_YN,
                        t1.SVC_MP4_YN,
                       Nvl((CASE WHEN t3.MEDIA_YN = 'Y' THEN t3.SVC_FLAC_YN ELSE 'N' END),'N') as SVC_FLAC_YN ,
                        t1.FULLHD_PRICE,
                        t1.HD_PRICE,
                        t1.SD_PRICE,
                        t3.track_group_id,
                        t1.search_title
                FROM    tmu_music@bugsmeta t1,
                        (select distinct track_id
                        from track_use_map@mcms t4,
                            --20110712 아래 뷰는 최상위 계약을 찾아낸다--
                           (select use_cont_id,company_id, connect_by_root use_cont_id root_id
                            from use_cont@mcms
                            start with pre_use_cont_id is null
                            connect by pre_use_cont_id=prior use_cont_id
                           ) t5
                           --!!!!!!!!!! 아래 반드시 계약번호 변경!!!!1--
                        where t4.use_cont_id=t5.use_cont_id and  t5.company_id IN (2090) and (SYSDATE BETWEEN t4.start_dt AND NVL(t4.end_dt, SYSDATE)) and t5.root_id=20963
                        ) t2,
                        ted_track@cfeel t3
                WHERE   t1.track_id      =t2.track_id
                    AND t1.track_id      =t3.track_id
                    and t3.svc_flac_yn='Y'
                    --2011.5.23. 수동전용 추가
                    and t1.album_id=P_ALBUM_ID;


                --2011.5.23. 뮤비를 위한 특정트랙만 등록해야할때 사용한다.
                --tecs_rights@mcms테이블에서 agent번호를 확인후 적용해야 하나 가상앨범은 agent정보가 없다고 보므로 이부분을 뺀다.
                 INSERT INTO /*+ append */
                        UNI_MUSIC
                SELECT  t1.MEDIA_NO,
                        t1.TRACK_ID,
                        t1.TRACK_TITLE,
                        t1.TRACK_NO,
                        t1.TITLE_YN,
                        t1.LEN,
                        t1.DISC_ID,
                        t1.LYRICS_TP,
                        t1.ARTIST_ID,
                        t1.ARTIST_NM,
                        t1.ALBUM_ID,
                        t1.ALBUM_TITLE,
                        t1.ALBUM_ARTIST_ID,
                        t1.ALBUM_ARTIST_NM,
                        t1.RELEASE_YMD,
                        t1.MV_ID,
                        t1.HIGHRATE_YN,
                        t1.NATION_CD,
                        t1.GENRE_CD,
                        t1.ADULT_YN,
                        t1.AMP3_YN,
                        t1.SVC_128_YN,
                        t1.SVC_192_YN,
                        t1.SVC_320_YN,
                        --2011.5.23. 다운로드 및 스트리밍은 불가상태로 만든다,--
                        'N' as STR_RIGHTS_YN,
                        'N' as DNL_RIGHTS_YN,
                        t1.MV_STR_YN,
                        t1.CRT_DT,
                        to_char(sysdate,'yyyymmddhh24miss'),
                        t1.DB_STS,
                        t1.AGENCY_ID,
                        t1.AGENCY_NM,
                        t1.GENRE_DTL,
                        t1.LIVEBELL_YN,
                        t1.SVC_FULLHD_YN,
                        t1.SVC_HD_YN,
                        t1.SVC_SD_YN,
                        t1.SVC_MP4_YN,
                       'N' as  SVC_FLAC_YN ,
                        t1.FULLHD_PRICE,
                        t1.HD_PRICE,
                        t1.SD_PRICE,
                        t3.track_group_id,
                        t1.search_title
                FROM    tmu_music@bugsmeta t1,
                        ted_track@cfeel t3
                WHERE  t1.track_id    =t3.track_id
                    and t1.album_id in  (289600)
                    --2011.5.23. 수동전용 추가
                    and t1.album_id=P_ALBUM_ID;

                COMMIT;
        END;
        --ALBUM
        BEGIN
                                --2011.5.23. 수동용 추가--
                delete from UNI_ALBUM where album_id=P_ALBUM_ID;

                INSERT INTO UNI_ALBUM
                SELECT  t1.ALBUM_ID,
                        t1.TITLE,
                        t1.SEARCH_TITLE,
                        t1.ARTIST_ID,
                        t1.ARTIST_NM,
                        t1.GENRE_CD,
                        t1.NATION_CD,
                        t1.AGENCY_ID,
                        t1.AGENCY_NM,
                        t1.RELEASE_YMD,
                        t1.KEYWORD,
                        t1.ALBUM_TP,
                        t1.CRT_DT,
                        t1.UPD_DT,
                        t1.DISK_CNT,
                        t1.DB_STS
                FROM    tmu_album@bugsmeta t1
                WHERE  exists   (SELECT 1 FROM UNI_MUSIC t2 WHERE t1.album_id=t2.album_id
                        )
                 --2011.5.23. 수동용 추가--
                and album_id=P_ALBUM_ID;
        END;
        --ARTIST
        BEGIN
                --2011.5.23. 수동용 추가--
                delete from uni_artist  t1 where  EXISTS
                        (SELECT 1
                        FROM    UNI_MUSIC t2,
                                cfeel.ted_trackartist@cfeel t3
                        WHERE   t1.artist_id=t3.artist_id
                            AND t2.track_id =t3.track_id
                            --2011.5.23. 수동용 추가--
                            and t2.album_id=P_ALBUM_ID
                            AND t3.db_sts   ='A'
                        );

                INSERT INTO UNI_ARTIST
                SELECT  t1.ARTIST_ID,
                        t1.ARTIST_NM,
                        t1.DISP_NM,
                        t1.KOR_NM,
                        t1.SRCH_NM,
                        t1.BIRTH_YMD,
                        t1.NATION_CD,
                        t1.GENRE_CD,
                        t1.GRP_CD,
                        t1.SEX_CD,
                        t1.HOMEPAGE_URL,
                        t1.ACT_START_YMD,
                        t1.ACT_END_YMD,
                        t1.CRT_DT,
                        t1.UPD_DT,
                        t1.DB_STS
                FROM    tmu_artist@bugsmeta t1
                WHERE   EXISTS
                        (SELECT 1
                        FROM    UNI_MUSIC t2,
                                cfeel.ted_trackartist@cfeel t3
                        WHERE   t1.artist_id=t3.artist_id
                            AND t2.track_id =t3.track_id
                            --2011.5.23. 수동용 추가--
                            and t2.album_id=P_ALBUM_ID
                            AND t3.db_sts   ='A'
                        );
        END;
        --MV
        BEGIN
                        --2011.5.23. 수동용 추가--
                 delete from UNI_MV where album_id=P_ALBUM_ID;

                INSERT INTO UNI_MV
                SELECT  t1.MV_ID,
                        t1.MV_TITLE,
                        t1.TRACK_ID,
                        t1.TRACK_TITLE,
                        t1.ARTIST_ID,
                        t1.ARTIST_NM,
                        t1.ALBUM_ID,
                        t1.NATION_CD,
                        t1.ALBUM_TITLE,
                        t1.HIGHRATE_YN,
                        t1.ACTOR,
                        t1.DSCR,
                        t1.RELEASE_YMD,
                        t1.CRT_DT,
                        t1.UPD_DT,
                        t1.DB_STS,
                        t1.SVC_FULLHD_YN,
                        t1.SVC_HD_YN,
                        t1.SVC_SD_YN,
                        t1.SVC_MP4_YN,
                        t1.MEDIA_NO,
                        decode(album_id,289600,'Y',t1.SVC_STR_YN) as svc_str_yn,
                        t1.attr_tp,
                        t1.FULLHD_PRICE,
                        t1.HD_PRICE,
                        t1.SD_PRICE
                FROM    tmu_mv@bugsmeta t1
                WHERE   EXISTS
                        (SELECT 1 FROM UNI_MUSIC t2 WHERE t1.track_id=t2.track_id
                        )
                                --2011.5.23. 수동용 추가--
                and  album_id=P_ALBUM_ID;
        END;
        --TRACKSTYLE
        BEGIN
               --2011.5.23. 수동용 추가--
                delete from UNI_TRACKSTYLE t1  where EXISTS
                        (SELECT 1 FROM UNI_MUSIC t2 WHERE t1.track_id=t2.track_id
                        --2011.5.23. 수동 추가--
                        and t2.album_id=P_ALBUM_ID
                        );

                INSERT INTO UNI_TRACKSTYLE
                SELECT  track_id,
                        style_id,
                        listorder,
                        crt_dt
                FROM    TBM_TRACKSTYLE@bugsmeta t1
                WHERE   EXISTS
                        (SELECT 1 FROM UNI_MUSIC t2 WHERE t1.track_id=t2.track_id
                        --2011.5.23. 수동 추가--
                        and t2.album_id=P_ALBUM_ID
                        );
        END;
        --ALBUM_PHOTO
        BEGIN

                --2011.5.23. 수동 추가--
                delete from uni_album_photo t1 where EXISTS
                        (SELECT 1 FROM uni_album t2 WHERE t1.album_id=t2.album_id
                        --2011.5.23. 수동 추가--
                        and t2.album_id=P_ALBUM_ID
                        );

                INSERT INTO uni_album_photo
                SELECT  album_id,
                        album_photo_id,
                        image,
                        repres_yn,
                        priority,
                        regdate
                FROM    album_photo@bugsmeta t1
                WHERE   EXISTS
                        (SELECT 1 FROM uni_album t2 WHERE t1.album_id=t2.album_id
                        --2011.5.23. 수동 추가--
                        and t2.album_id=P_ALBUM_ID
                        );
        END;
        --ARTIST_PHOTO
        BEGIN
                m_sql :='truncate  table   UNI_ARTIST_PHOTO';
                EXECUTE IMMEDIATE m_sql;
                INSERT INTO uni_artist_photo
                SELECT  artist_id,
                        artist_photo_id,
                        image,
                        repres_yn,
                        priority,
                        regdate
                FROM    artist_photo@bugsmeta t1
                WHERE   EXISTS
                        (SELECT 1 FROM uni_artist t2 WHERE t1.artist_id=t2.artist_id
                        );
        END;
        --codedtl
        BEGIN
                MERGE INTO codedtl a USING
                (SELECT cd_dtl_cd,
                        cd_id,
                        cd_dtl_nm,
                        cd_dtl_exp,
                        prir_seq,
                        crt_dt,
                        upd_id,
                        db_sts
                FROM    tfm_codedtl@cfeel
                ) b ON (a.cd_dtl_cd=b.cd_dtl_cd AND a.cd_id=b.cd_id)
        WHEN MATCHED THEN
                UPDATE
                SET     a.cd_dtl_nm = b.cd_dtl_nm,
                        a.cd_dtl_exp=b.cd_dtl_exp,
                        a.prir_seq  =b.prir_seq,
                        a.crt_dt    =b.crt_dt,
                        a.upd_id    =b.upd_id,
                        a.db_sts    =b.db_sts WHEN NOT MATCHED THEN
                INSERT
                        (
                                cd_dtl_cd,
                                cd_id,
                                cd_dtl_nm,
                                cd_dtl_exp,
                                prir_seq,
                                crt_dt,
                                upd_id,
                                db_sts
                        )
                        VALUES
                        (
                                b.cd_dtl_cd,
                                b.cd_id,
                                b.cd_dtl_nm,
                                b.cd_dtl_exp,
                                b.prir_seq,
                                b.crt_dt,
                                b.upd_id,
                                b.db_sts
                        );
        END;
        --TRACKARTIST
        BEGIN
                --#### 2011.1.13. 추가 ###--------
                --대표아티스므만 순번이 0이고 나머지는 전부 1이다.

                --2011.5.23. 수동 추가--
                delete from uni_trackartist t1 where EXISTS
                        (SELECT 1 FROM uni_music t2 WHERE t1.track_id=t2.track_id
                        --2011.5.23. 수동 추가--
                        and t2.album_id=P_ALBUM_ID
                        );

                INSERT INTO uni_trackartist
                SELECT  a.TRACKARTIST_ID ,
                        a.ARTIST_ID,
                        a.TRACK_ID,
                        a.RP_CD,
                        DECODE(a.rp_cd,'Y',0,1) AS ARTIST_PRIOR,
                        b.cd_id,
                        b.cd_dtl_cd,
                        a.crt_dt
                FROM    ted_trackartist@cfeel a ,
                        codedtl b
                WHERE   EXISTS
                        (SELECT 1 FROM uni_music c WHERE a.track_id=c.track_id
                        --2011.5.23. 수동 추가--
                        and c.album_id=P_ALBUM_ID
                        )
                    AND a.role_cd=b.cd_dtl_cd
                    AND b.cd_id  =22
                    AND a.db_sts ='A';
        END;

        --GENRE
        BEGIN
                MERGE INTO genre a USING
                ( SELECT genre_cd, genre_nm FROM tmu_genre@cfeel WHERE genre_cd = pgenre_cd
                ) b ON (a.genre_id = b.genre_cd)
        WHEN MATCHED THEN
                UPDATE SET a.genre_nm = b.genre_nm WHEN NOT MATCHED THEN
                INSERT
                        (
                                genre_id,
                                genre_nm,
                                crt_dt
                        )
                        VALUES
                        (
                                b.genre_cd,
                                b.genre_nm,
                                sysdate
                        );
        END;
        --STYLE
        BEGIN
                MERGE INTO style a USING
                (SELECT genre_cd,
                                pgenre_cd,
                                genre_nm
                        FROM    tmu_genre@cfeel aa
                        WHERE   genre_cd != pgenre_cd
                            AND EXISTS
                                (SELECT 1 FROM genre bb WHERE aa.genre_cd = bb.genre_id
                                )
                )
                b ON (a.style_id = b.pgenre_cd)
        WHEN MATCHED THEN
                UPDATE SET a.style_nm = b.genre_nm WHEN NOT MATCHED THEN
                INSERT
                        (
                                style_id,
                                genre_id,
                                style_nm,
                                crt_dt
                        )
                        VALUES
                        (
                                b.pgenre_cd,
                                b.genre_cd,
                                b.genre_nm,
                                sysdate
                        );
        END ;
        COMMIT;
END universal_manual_meta;

END unimeta_util;
/

GRANT EXECUTE ON unimeta_util TO "SYSTEM"
/
