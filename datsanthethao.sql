USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = N'DatSanTheThao')
BEGIN
    ALTER DATABASE DatSanTheThao SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DatSanTheThao;
END
GO

CREATE DATABASE DatSanTheThao;
GO

ALTER DATABASE DatSanTheThao SET RECOVERY SIMPLE;
ALTER DATABASE DatSanTheThao SET READ_COMMITTED_SNAPSHOT ON;
GO

USE DatSanTheThao;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'app')
    EXEC('CREATE SCHEMA app AUTHORIZATION dbo');
GO

USE DatSanTheThao;
GO

-- 1.1. VaiTro
CREATE TABLE app.VaiTro
(
    VaiTroId        INT             IDENTITY(1,1) NOT NULL,
    MaVaiTro        NVARCHAR(50)    NOT NULL,
    TenVaiTro       NVARCHAR(100)   NOT NULL,
    MoTa            NVARCHAR(500)   NULL,
    NgayTaoUtc      DATETIME2(3)    NOT NULL CONSTRAINT DF_VaiTro_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_VaiTro PRIMARY KEY CLUSTERED (VaiTroId),
    CONSTRAINT UQ_VaiTro_MaVaiTro UNIQUE (MaVaiTro)
);
GO

-- 1.2. NguoiDung
CREATE TABLE app.NguoiDung
(
    NguoiDungId     UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_NguoiDung_Id DEFAULT NEWSEQUENTIALID(),
    TenDangNhap     NVARCHAR(50)     NOT NULL,
    MatKhauHash     NVARCHAR(255)    NOT NULL,
    MatKhauSalt     NVARCHAR(128)    NOT NULL,
    HoTen           NVARCHAR(150)    NOT NULL,
    Email           NVARCHAR(255)    NULL,
    SoDienThoai     NVARCHAR(20)     NOT NULL,
    AnhDaiDien      NVARCHAR(500)    NULL,
    NgaySinh        DATE             NULL,
    GioiTinh        TINYINT          NULL,
    DiaChi          NVARCHAR(500)    NULL,
    TrangThai       TINYINT          NOT NULL CONSTRAINT DF_NguoiDung_TrangThai DEFAULT (1),
    LanDangNhapCuoiUtc DATETIME2(3)  NULL,
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_NguoiDung_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    NgayCapNhatUtc  DATETIME2(3)     NULL,
    DaXoa           BIT              NOT NULL CONSTRAINT DF_NguoiDung_DaXoa DEFAULT (0),
    RowVersion      ROWVERSION       NOT NULL,
    CONSTRAINT PK_NguoiDung PRIMARY KEY CLUSTERED (NguoiDungId),
    CONSTRAINT CK_NguoiDung_TrangThai CHECK (TrangThai IN (0,1,2,3)),
    CONSTRAINT CK_NguoiDung_GioiTinh  CHECK (GioiTinh IS NULL OR GioiTinh IN (0,1,2))
);
GO

CREATE UNIQUE INDEX UX_NguoiDung_TenDangNhap
    ON app.NguoiDung (TenDangNhap) WHERE DaXoa = 0;
CREATE UNIQUE INDEX UX_NguoiDung_SoDienThoai
    ON app.NguoiDung (SoDienThoai) WHERE DaXoa = 0;
CREATE UNIQUE INDEX UX_NguoiDung_Email
    ON app.NguoiDung (Email) WHERE DaXoa = 0 AND Email IS NOT NULL;
GO

-- 1.3. NguoiDungVaiTro
CREATE TABLE app.NguoiDungVaiTro
(
    NguoiDungId     UNIQUEIDENTIFIER NOT NULL,
    VaiTroId        INT              NOT NULL,
    NgayGanUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_NDVT_NgayGanUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_NguoiDungVaiTro PRIMARY KEY CLUSTERED (NguoiDungId, VaiTroId),
    CONSTRAINT FK_NDVT_NguoiDung FOREIGN KEY (NguoiDungId) REFERENCES app.NguoiDung(NguoiDungId) ON DELETE CASCADE,
    CONSTRAINT FK_NDVT_VaiTro    FOREIGN KEY (VaiTroId)    REFERENCES app.VaiTro(VaiTroId)
);
GO

-- 1.4. RefreshToken
CREATE TABLE app.RefreshToken
(
    RefreshTokenId  BIGINT           IDENTITY(1,1) NOT NULL,
    NguoiDungId     UNIQUEIDENTIFIER NOT NULL,
    MaTokenHash     NVARCHAR(255)    NOT NULL,
    ThietBiId       NVARCHAR(200)    NULL,
    DiaChiIp        NVARCHAR(45)     NULL,
    ThoiGianHetHanUtc DATETIME2(3)   NOT NULL,
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_RFT_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    NgayThuHoiUtc   DATETIME2(3)     NULL,
    TokenChaId      BIGINT           NULL,
    LyDoThuHoi      NVARCHAR(200)    NULL,
    CONSTRAINT PK_RefreshToken PRIMARY KEY CLUSTERED (RefreshTokenId),
    CONSTRAINT FK_RFT_NguoiDung FOREIGN KEY (NguoiDungId) REFERENCES app.NguoiDung(NguoiDungId) ON DELETE CASCADE,
    CONSTRAINT FK_RFT_TokenCha  FOREIGN KEY (TokenChaId)  REFERENCES app.RefreshToken(RefreshTokenId)
);
GO

CREATE UNIQUE INDEX UX_RefreshToken_MaTokenHash ON app.RefreshToken (MaTokenHash);
GO

-- 1.5. ThietBiNguoiDung
CREATE TABLE app.ThietBiNguoiDung
(
    ThietBiId       BIGINT           IDENTITY(1,1) NOT NULL,
    NguoiDungId     UNIQUEIDENTIFIER NOT NULL,
    FcmToken        NVARCHAR(500)    NOT NULL,
    NenTang         TINYINT          NOT NULL,
    TenThietBi      NVARCHAR(200)    NULL,
    PhienBanApp     NVARCHAR(50)     NULL,
    LanHoatDongCuoiUtc DATETIME2(3)  NOT NULL CONSTRAINT DF_TBND_LanHoatDongCuoiUtc DEFAULT SYSUTCDATETIME(),
    DangHoatDong    BIT              NOT NULL CONSTRAINT DF_TBND_DangHoatDong DEFAULT (1),
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_TBND_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_ThietBiNguoiDung PRIMARY KEY CLUSTERED (ThietBiId),
    CONSTRAINT FK_TBND_NguoiDung FOREIGN KEY (NguoiDungId) REFERENCES app.NguoiDung(NguoiDungId) ON DELETE CASCADE,
    CONSTRAINT CK_TBND_NenTang CHECK (NenTang IN (1,2,3))
);
GO

CREATE UNIQUE INDEX UX_TBND_FcmToken ON app.ThietBiNguoiDung (FcmToken);
GO

-- SELECT name FROM sys.tables WHERE schema_id = SCHEMA_ID('app') ORDER BY name;
-- Kỳ vọng: NguoiDung, NguoiDungVaiTro, RefreshToken, ThietBiNguoiDung, VaiTro

USE DatSanTheThao;
GO

-- 2.1. ChiNhanh
CREATE TABLE app.ChiNhanh
(
    ChiNhanhId      INT              IDENTITY(1,1) NOT NULL,
    MaChiNhanh      NVARCHAR(50)     NOT NULL,
    TenChiNhanh     NVARCHAR(200)    NOT NULL,
    DiaChi          NVARCHAR(500)    NOT NULL,
    ViDo            DECIMAL(10,7)    NULL,
    KinhDo          DECIMAL(10,7)    NULL,
    SoDienThoai     NVARCHAR(20)     NULL,
    Email           NVARCHAR(255)    NULL,
    MoTa            NVARCHAR(2000)   NULL,
    GioMoCua        TIME(0)          NOT NULL CONSTRAINT DF_CN_GioMoCua  DEFAULT ('06:00:00'),
    GioDongCua      TIME(0)          NOT NULL CONSTRAINT DF_CN_GioDongCua DEFAULT ('23:00:00'),
    TrangThai       TINYINT          NOT NULL CONSTRAINT DF_CN_TrangThai DEFAULT (1),
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_CN_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    NgayCapNhatUtc  DATETIME2(3)     NULL,
    DaXoa           BIT              NOT NULL CONSTRAINT DF_CN_DaXoa DEFAULT (0),
    RowVersion      ROWVERSION       NOT NULL,
    CONSTRAINT PK_ChiNhanh PRIMARY KEY CLUSTERED (ChiNhanhId),
    CONSTRAINT UQ_ChiNhanh_MaChiNhanh UNIQUE (MaChiNhanh),
    CONSTRAINT CK_ChiNhanh_Gio CHECK (GioDongCua > GioMoCua)
);
GO

-- 2.2. AnhChiNhanh
CREATE TABLE app.AnhChiNhanh
(
    AnhChiNhanhId   BIGINT           IDENTITY(1,1) NOT NULL,
    ChiNhanhId      INT              NOT NULL,
    DuongDanAnh     NVARCHAR(500)    NOT NULL,
    ThuTuHienThi    INT              NOT NULL CONSTRAINT DF_ACN_ThuTu DEFAULT (0),
    LaAnhChinh      BIT              NOT NULL CONSTRAINT DF_ACN_LaAnhChinh DEFAULT (0),
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_ACN_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_AnhChiNhanh PRIMARY KEY CLUSTERED (AnhChiNhanhId),
    CONSTRAINT FK_ACN_ChiNhanh FOREIGN KEY (ChiNhanhId) REFERENCES app.ChiNhanh(ChiNhanhId) ON DELETE CASCADE
);
GO

-- 2.3. LoaiSan
CREATE TABLE app.LoaiSan
(
    LoaiSanId       INT              IDENTITY(1,1) NOT NULL,
    MaLoaiSan       NVARCHAR(50)     NOT NULL,
    TenLoaiSan      NVARCHAR(150)    NOT NULL,
    MoTa            NVARCHAR(1000)   NULL,
    SoNguoiToiDa    INT              NULL,
    PhutMoiSlot     INT              NOT NULL CONSTRAINT DF_LS_PhutMoiSlot DEFAULT (30),
    ThoiLuongToiThieuPhut INT        NOT NULL CONSTRAINT DF_LS_ThoiLuongMin DEFAULT (60),
    ThoiLuongToiDaPhut     INT       NOT NULL CONSTRAINT DF_LS_ThoiLuongMax DEFAULT (180),
    TrangThai       TINYINT          NOT NULL CONSTRAINT DF_LS_TrangThai DEFAULT (1),
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_LS_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    DaXoa           BIT              NOT NULL CONSTRAINT DF_LS_DaXoa DEFAULT (0),
    CONSTRAINT PK_LoaiSan PRIMARY KEY CLUSTERED (LoaiSanId),
    CONSTRAINT UQ_LoaiSan_MaLoaiSan UNIQUE (MaLoaiSan),
    CONSTRAINT CK_LS_PhutMoiSlot CHECK (PhutMoiSlot IN (15, 20, 30, 60)),
    CONSTRAINT CK_LS_ThoiLuong   CHECK (ThoiLuongToiDaPhut >= ThoiLuongToiThieuPhut)
);
GO

-- 2.4. San
CREATE TABLE app.San
(
    SanId           INT              IDENTITY(1,1) NOT NULL,
    ChiNhanhId      INT              NOT NULL,
    LoaiSanId       INT              NOT NULL,
    MaSan           NVARCHAR(50)     NOT NULL,
    TenSan          NVARCHAR(200)    NOT NULL,
    MoTa            NVARCHAR(2000)   NULL,
    SucChua         INT              NULL,
    ViTri           NVARCHAR(200)    NULL,
    GiaCoBan        DECIMAL(18,0)    NOT NULL,
    AnhDaiDien      NVARCHAR(500)    NULL,
    TrangThai       TINYINT          NOT NULL CONSTRAINT DF_San_TrangThai DEFAULT (1),
    ChoPhepDatTruocNgay INT          NOT NULL CONSTRAINT DF_San_ChoPhepDatTruoc DEFAULT (14),
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_San_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    NgayCapNhatUtc  DATETIME2(3)     NULL,
    DaXoa           BIT              NOT NULL CONSTRAINT DF_San_DaXoa DEFAULT (0),
    RowVersion      ROWVERSION       NOT NULL,
    CONSTRAINT PK_San PRIMARY KEY CLUSTERED (SanId),
    CONSTRAINT FK_San_ChiNhanh FOREIGN KEY (ChiNhanhId) REFERENCES app.ChiNhanh(ChiNhanhId),
    CONSTRAINT FK_San_LoaiSan  FOREIGN KEY (LoaiSanId)  REFERENCES app.LoaiSan(LoaiSanId),
    CONSTRAINT UQ_San_ChiNhanh_MaSan UNIQUE (ChiNhanhId, MaSan),
    CONSTRAINT CK_San_GiaCoBan CHECK (GiaCoBan >= 0)
);
GO

-- 2.5. AnhSan
CREATE TABLE app.AnhSan
(
    AnhSanId        BIGINT           IDENTITY(1,1) NOT NULL,
    SanId           INT              NOT NULL,
    DuongDanAnh     NVARCHAR(500)    NOT NULL,
    ThuTuHienThi    INT              NOT NULL CONSTRAINT DF_AS_ThuTu DEFAULT (0),
    LaAnhChinh      BIT              NOT NULL CONSTRAINT DF_AS_LaAnhChinh DEFAULT (0),
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_AS_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_AnhSan PRIMARY KEY CLUSTERED (AnhSanId),
    CONSTRAINT FK_AS_San FOREIGN KEY (SanId) REFERENCES app.San(SanId) ON DELETE CASCADE
);
GO

-- 2.6. TienIch + SanTienIch
CREATE TABLE app.TienIch
(
    TienIchId       INT              IDENTITY(1,1) NOT NULL,
    MaTienIch       NVARCHAR(50)     NOT NULL,
    TenTienIch      NVARCHAR(150)    NOT NULL,
    BieuTuong       NVARCHAR(100)    NULL,
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_TI_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_TienIch PRIMARY KEY CLUSTERED (TienIchId),
    CONSTRAINT UQ_TienIch_MaTienIch UNIQUE (MaTienIch)
);
GO

CREATE TABLE app.SanTienIch
(
    SanId           INT NOT NULL,
    TienIchId       INT NOT NULL,
    CONSTRAINT PK_SanTienIch PRIMARY KEY CLUSTERED (SanId, TienIchId),
    CONSTRAINT FK_STI_San     FOREIGN KEY (SanId)     REFERENCES app.San(SanId) ON DELETE CASCADE,
    CONSTRAINT FK_STI_TienIch FOREIGN KEY (TienIchId) REFERENCES app.TienIch(TienIchId)
);
GO

USE DatSanTheThao;
GO

CREATE TABLE app.QuyTacGia
(
    QuyTacGiaId     INT              IDENTITY(1,1) NOT NULL,
    ChiNhanhId      INT              NOT NULL,
    SanId           INT              NULL,
    LoaiSanId       INT              NULL,
    TenQuyTac       NVARCHAR(200)    NOT NULL,
    ThuTrongTuan    TINYINT          NULL,
    LaNgayLe        BIT              NOT NULL CONSTRAINT DF_QTG_LaNgayLe DEFAULT (0),
    GioBatDau       TIME(0)          NOT NULL,
    GioKetThuc      TIME(0)          NOT NULL,
    GiaMoiGio       DECIMAL(18,0)    NOT NULL,
    UuTien          INT              NOT NULL CONSTRAINT DF_QTG_UuTien DEFAULT (0),
    HieuLucTuUtc    DATETIME2(3)     NULL,
    HieuLucDenUtc   DATETIME2(3)     NULL,
    TrangThai       TINYINT          NOT NULL CONSTRAINT DF_QTG_TrangThai DEFAULT (1),
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_QTG_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    DaXoa           BIT              NOT NULL CONSTRAINT DF_QTG_DaXoa DEFAULT (0),
    CONSTRAINT PK_QuyTacGia PRIMARY KEY CLUSTERED (QuyTacGiaId),
    CONSTRAINT FK_QTG_ChiNhanh FOREIGN KEY (ChiNhanhId) REFERENCES app.ChiNhanh(ChiNhanhId),
    CONSTRAINT FK_QTG_San      FOREIGN KEY (SanId)      REFERENCES app.San(SanId),
    CONSTRAINT FK_QTG_LoaiSan  FOREIGN KEY (LoaiSanId)  REFERENCES app.LoaiSan(LoaiSanId),
    CONSTRAINT CK_QTG_Gio      CHECK (GioKetThuc > GioBatDau),
    CONSTRAINT CK_QTG_Gia      CHECK (GiaMoiGio >= 0)
);
GO

CREATE TABLE app.NgayDacBiet
(
    NgayDacBietId   INT              IDENTITY(1,1) NOT NULL,
    ChiNhanhId      INT              NULL,
    Ngay            DATE             NOT NULL,
    TenNgay         NVARCHAR(200)    NOT NULL,
    LaNgayLe        BIT              NOT NULL CONSTRAINT DF_NDB_LaNgayLe DEFAULT (1),
    HeSoGia         DECIMAL(5,2)     NOT NULL CONSTRAINT DF_NDB_HeSoGia DEFAULT (1.00),
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_NDB_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_NgayDacBiet PRIMARY KEY CLUSTERED (NgayDacBietId),
    CONSTRAINT FK_NDB_ChiNhanh FOREIGN KEY (ChiNhanhId) REFERENCES app.ChiNhanh(ChiNhanhId)
);
GO

CREATE UNIQUE INDEX UX_NDB_ChiNhanh_Ngay ON app.NgayDacBiet (ChiNhanhId, Ngay);
GO

USE DatSanTheThao;
GO

CREATE TABLE app.KhuyenMai
(
    KhuyenMaiId     INT              IDENTITY(1,1) NOT NULL,
    MaKhuyenMai     NVARCHAR(50)     NOT NULL,
    TenKhuyenMai    NVARCHAR(200)    NOT NULL,
    MoTa            NVARCHAR(1000)   NULL,
    LoaiGiam        TINYINT          NOT NULL,
    GiaTriGiam      DECIMAL(18,2)    NOT NULL,
    GiamToiDa       DECIMAL(18,0)    NULL,
    DonHangToiThieu DECIMAL(18,0)    NOT NULL CONSTRAINT DF_KM_DonHangToiThieu DEFAULT (0),
    HieuLucTuUtc    DATETIME2(3)     NOT NULL,
    HieuLucDenUtc   DATETIME2(3)     NOT NULL,
    SoLanSuDungToiDa INT             NULL,
    SoLanMoiNguoiToiDa INT           NULL,
    SoLanDaSuDung   INT              NOT NULL CONSTRAINT DF_KM_SoLanDaSuDung DEFAULT (0),
    ApDungChiNhanhId INT             NULL,
    ApDungLoaiSanId  INT             NULL,
    TrangThai       TINYINT          NOT NULL CONSTRAINT DF_KM_TrangThai DEFAULT (1),
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_KM_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    DaXoa           BIT              NOT NULL CONSTRAINT DF_KM_DaXoa DEFAULT (0),
    RowVersion      ROWVERSION       NOT NULL,
    CONSTRAINT PK_KhuyenMai PRIMARY KEY CLUSTERED (KhuyenMaiId),
    CONSTRAINT UQ_KhuyenMai_Ma UNIQUE (MaKhuyenMai),
    CONSTRAINT CK_KM_LoaiGiam CHECK (LoaiGiam IN (1,2)),
    CONSTRAINT CK_KM_GiaTri   CHECK (GiaTriGiam > 0),
    CONSTRAINT CK_KM_HieuLuc  CHECK (HieuLucDenUtc > HieuLucTuUtc)
);
GO

USE DatSanTheThao;
GO

-- 5.1. DatSan
CREATE TABLE app.DatSan
(
    DatSanId        UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_DatSan_Id DEFAULT NEWSEQUENTIALID(),
    MaDatSan        NVARCHAR(30)     NOT NULL,
    NguoiDungId     UNIQUEIDENTIFIER NOT NULL,
    ChiNhanhId      INT              NOT NULL,
    SanId           INT              NOT NULL,
    LoaiSanId       INT              NOT NULL,
    ThoiGianBatDauUtc  DATETIME2(3)  NOT NULL,
    ThoiGianKetThucUtc DATETIME2(3)  NOT NULL,
    ThoiLuongPhut      INT           NOT NULL,
    MuiGio             NVARCHAR(10)  NOT NULL CONSTRAINT DF_DatSan_MuiGio DEFAULT ('SE Asia Standard Time'),
    TrangThai       NVARCHAR(30)     NOT NULL CONSTRAINT DF_DatSan_TrangThai DEFAULT ('PENDING_PAYMENT'),
    GiaGoc          DECIMAL(18,0)    NOT NULL,
    TienGiam        DECIMAL(18,0)    NOT NULL CONSTRAINT DF_DatSan_TienGiam DEFAULT (0),
    TongTien        DECIMAL(18,0)    NOT NULL,
    KhuyenMaiId     INT              NULL,
    GhiChu          NVARCHAR(1000)   NULL,
    NguonDat        TINYINT          NOT NULL CONSTRAINT DF_DatSan_NguonDat DEFAULT (1),
    ThoiGianHetHanThanhToanUtc DATETIME2(3) NULL,
    ThoiGianThanhToanUtc       DATETIME2(3) NULL,
    ThoiGianHuyUtc             DATETIME2(3) NULL,
    LyDoHuy         NVARCHAR(500)    NULL,
    ThoiGianCheckInUtc   DATETIME2(3) NULL,
    ThoiGianCheckOutUtc  DATETIME2(3) NULL,
    LaQuaGio        BIT              NOT NULL CONSTRAINT DF_DatSan_LaQuaGio DEFAULT (0),
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_DatSan_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    NgayCapNhatUtc  DATETIME2(3)     NULL,
    RowVersion      ROWVERSION       NOT NULL,
    CONSTRAINT PK_DatSan PRIMARY KEY CLUSTERED (DatSanId),
    CONSTRAINT UQ_DatSan_MaDatSan UNIQUE (MaDatSan),
    CONSTRAINT FK_DatSan_NguoiDung  FOREIGN KEY (NguoiDungId) REFERENCES app.NguoiDung(NguoiDungId),
    CONSTRAINT FK_DatSan_ChiNhanh   FOREIGN KEY (ChiNhanhId)  REFERENCES app.ChiNhanh(ChiNhanhId),
    CONSTRAINT FK_DatSan_San        FOREIGN KEY (SanId)       REFERENCES app.San(SanId),
    CONSTRAINT FK_DatSan_LoaiSan    FOREIGN KEY (LoaiSanId)   REFERENCES app.LoaiSan(LoaiSanId),
    CONSTRAINT FK_DatSan_KhuyenMai  FOREIGN KEY (KhuyenMaiId) REFERENCES app.KhuyenMai(KhuyenMaiId),
    CONSTRAINT CK_DatSan_ThoiGian   CHECK (ThoiGianKetThucUtc > ThoiGianBatDauUtc),
    CONSTRAINT CK_DatSan_ThoiLuong  CHECK (ThoiLuongPhut > 0),
    CONSTRAINT CK_DatSan_Tien       CHECK (GiaGoc >= 0 AND TienGiam >= 0 AND TongTien >= 0 AND TongTien = GiaGoc - TienGiam),
    CONSTRAINT CK_DatSan_TrangThai  CHECK (TrangThai IN
        ('PENDING_PAYMENT','LOCKED','PAID','CHECKED_IN','IN_PROGRESS',
         'COMPLETED','CANCELLED','EXPIRED','REFUNDED'))
);
GO

CREATE INDEX IX_DatSan_NguoiDung_TrangThai
    ON app.DatSan (NguoiDungId, TrangThai, ThoiGianBatDauUtc DESC)
    INCLUDE (MaDatSan, SanId, ChiNhanhId, TongTien);

CREATE INDEX IX_DatSan_San_ThoiGian
    ON app.DatSan (SanId, ThoiGianBatDauUtc, ThoiGianKetThucUtc)
    INCLUDE (TrangThai, NguoiDungId);

CREATE INDEX IX_DatSan_HetHanThanhToan
    ON app.DatSan (ThoiGianHetHanThanhToanUtc)
    WHERE TrangThai = 'PENDING_PAYMENT';

CREATE INDEX IX_DatSan_SapKetThuc
    ON app.DatSan (ThoiGianKetThucUtc)
    WHERE TrangThai IN ('PAID','CHECKED_IN','IN_PROGRESS');

CREATE INDEX IX_DatSan_ChiNhanh_Ngay
    ON app.DatSan (ChiNhanhId, ThoiGianBatDauUtc)
    INCLUDE (SanId, TrangThai, TongTien);
GO

-- 5.2. DatSanChiTiet — ★ CHỐNG DOUBLE BOOKING ★
CREATE TABLE app.DatSanChiTiet
(
    DatSanChiTietId BIGINT           IDENTITY(1,1) NOT NULL,
    DatSanId        UNIQUEIDENTIFIER NOT NULL,
    SanId           INT              NOT NULL,
    ChiNhanhId      INT              NOT NULL,
    NgaySuDung      DATE             NOT NULL,
    ThoiGianBatDauUtc  DATETIME2(3)  NOT NULL,
    ThoiGianKetThucUtc DATETIME2(3)  NOT NULL,
    ThuTuSlot       INT              NOT NULL,
    GiaSlot         DECIMAL(18,0)    NOT NULL,
    TrangThai       NVARCHAR(20)     NOT NULL CONSTRAINT DF_DSCT_TrangThai DEFAULT ('HELD'),
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_DSCT_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_DatSanChiTiet PRIMARY KEY CLUSTERED (DatSanChiTietId),
    CONSTRAINT FK_DSCT_DatSan   FOREIGN KEY (DatSanId)   REFERENCES app.DatSan(DatSanId) ON DELETE CASCADE,
    CONSTRAINT FK_DSCT_San      FOREIGN KEY (SanId)      REFERENCES app.San(SanId),
    CONSTRAINT FK_DSCT_ChiNhanh FOREIGN KEY (ChiNhanhId) REFERENCES app.ChiNhanh(ChiNhanhId),
    CONSTRAINT CK_DSCT_ThoiGian CHECK (ThoiGianKetThucUtc > ThoiGianBatDauUtc),
    CONSTRAINT CK_DSCT_TrangThai CHECK (TrangThai IN ('HELD','BOOKED','RELEASED','COMPLETED')),
    CONSTRAINT CK_DSCT_Gia CHECK (GiaSlot >= 0)
);
GO

-- ★★ UNIQUE INDEX CHỐNG DOUBLE BOOKING ★★
CREATE UNIQUE INDEX UX_DSCT_San_Slot_DangChiem
    ON app.DatSanChiTiet (SanId, ThoiGianBatDauUtc)
    WHERE TrangThai IN ('HELD','BOOKED','COMPLETED');

CREATE INDEX IX_DSCT_San_Ngay
    ON app.DatSanChiTiet (SanId, NgaySuDung, ThoiGianBatDauUtc)
    INCLUDE (ThoiGianKetThucUtc, TrangThai, DatSanId);

CREATE INDEX IX_DSCT_DatSan ON app.DatSanChiTiet (DatSanId);
GO

-- 5.3. KhoaTam — Soft-Lock 5 phút
CREATE TABLE app.KhoaTam
(
    KhoaTamId       UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_KhoaTam_Id DEFAULT NEWSEQUENTIALID(),
    DatSanId        UNIQUEIDENTIFIER NOT NULL,
    NguoiDungId     UNIQUEIDENTIFIER NOT NULL,
    SanId           INT              NOT NULL,
    ChiNhanhId      INT              NOT NULL,
    NgaySuDung      DATE             NOT NULL,
    ThoiGianBatDauUtc  DATETIME2(3)  NOT NULL,
    ThoiGianKetThucUtc DATETIME2(3)  NOT NULL,
    TrangThai       NVARCHAR(20)     NOT NULL CONSTRAINT DF_KhoaTam_TrangThai DEFAULT ('ACTIVE'),
    ThoiGianHetHanUtc  DATETIME2(3)  NOT NULL,
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_KhoaTam_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    NgayGiaiPhongUtc DATETIME2(3)    NULL,
    LyDoGiaiPhong   NVARCHAR(200)    NULL,
    RowVersion      ROWVERSION       NOT NULL,
    CONSTRAINT PK_KhoaTam PRIMARY KEY CLUSTERED (KhoaTamId),
    CONSTRAINT FK_KhoaTam_DatSan    FOREIGN KEY (DatSanId)    REFERENCES app.DatSan(DatSanId) ON DELETE CASCADE,
    CONSTRAINT FK_KhoaTam_NguoiDung FOREIGN KEY (NguoiDungId) REFERENCES app.NguoiDung(NguoiDungId),
    CONSTRAINT FK_KhoaTam_San       FOREIGN KEY (SanId)       REFERENCES app.San(SanId),
    CONSTRAINT FK_KhoaTam_ChiNhanh  FOREIGN KEY (ChiNhanhId)  REFERENCES app.ChiNhanh(ChiNhanhId),
    CONSTRAINT CK_KhoaTam_ThoiGian  CHECK (ThoiGianKetThucUtc > ThoiGianBatDauUtc),
    CONSTRAINT CK_KhoaTam_TrangThai CHECK (TrangThai IN ('ACTIVE','RELEASED','EXPIRED','CONSUMED')),
    CONSTRAINT CK_KhoaTam_HetHan    CHECK (ThoiGianHetHanUtc > NgayTaoUtc)
);
GO

-- ★ Một slot của một sân chỉ có 1 khóa ACTIVE ★
CREATE UNIQUE INDEX UX_KhoaTam_San_Slot_Active
    ON app.KhoaTam (SanId, ThoiGianBatDauUtc)
    WHERE TrangThai = 'ACTIVE';

CREATE INDEX IX_KhoaTam_HetHan ON app.KhoaTam (ThoiGianHetHanUtc)
    WHERE TrangThai = 'ACTIVE';

CREATE INDEX IX_KhoaTam_NguoiDung ON app.KhoaTam (NguoiDungId, TrangThai)
    INCLUDE (DatSanId, SanId, ThoiGianBatDauUtc, ThoiGianHetHanUtc);
GO

USE DatSanTheThao;
GO

CREATE TABLE app.ThanhToan
(
    ThanhToanId     UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_ThanhToan_Id DEFAULT NEWSEQUENTIALID(),
    MaDonHang       NVARCHAR(50)     NOT NULL,
    DatSanId        UNIQUEIDENTIFIER NOT NULL,
    NguoiDungId     UNIQUEIDENTIFIER NOT NULL,
    CongThanhToan   NVARCHAR(30)     NOT NULL,
    PhuongThuc      NVARCHAR(30)     NULL,
    SoTien          DECIMAL(18,0)    NOT NULL,
    TienTe          NVARCHAR(10)     NOT NULL CONSTRAINT DF_ThanhToan_TienTe DEFAULT ('VND'),
    TrangThai       NVARCHAR(20)     NOT NULL CONSTRAINT DF_ThanhToan_TrangThai DEFAULT ('PENDING'),
    ThoiGianHetHanUtc  DATETIME2(3)  NOT NULL,
    ThoiGianThanhToanUtc DATETIME2(3) NULL,
    UrlThanhToan    NVARCHAR(2000)   NULL,
    MaThamChieuCong NVARCHAR(100)    NULL,
    LyDoThatBai     NVARCHAR(500)    NULL,
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_ThanhToan_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    NgayCapNhatUtc  DATETIME2(3)     NULL,
    RowVersion      ROWVERSION       NOT NULL,
    CONSTRAINT PK_ThanhToan PRIMARY KEY CLUSTERED (ThanhToanId),
    CONSTRAINT UQ_ThanhToan_MaDonHang UNIQUE (MaDonHang),
    CONSTRAINT FK_ThanhToan_DatSan    FOREIGN KEY (DatSanId)    REFERENCES app.DatSan(DatSanId),
    CONSTRAINT FK_ThanhToan_NguoiDung FOREIGN KEY (NguoiDungId) REFERENCES app.NguoiDung(NguoiDungId),
    CONSTRAINT CK_ThanhToan_SoTien    CHECK (SoTien > 0),
    CONSTRAINT CK_ThanhToan_TrangThai CHECK (TrangThai IN ('PENDING','SUCCESS','FAILED','CANCELLED','REFUNDED')),
    CONSTRAINT CK_ThanhToan_Cong      CHECK (CongThanhToan IN ('VNPAY','VIETQR','MOMO','ZALOPAY','STRIPE','CASH'))
);
GO

CREATE UNIQUE INDEX UX_ThanhToan_DatSan_DangHieuLuc
    ON app.ThanhToan (DatSanId)
    WHERE TrangThai IN ('PENDING','SUCCESS');

CREATE INDEX IX_ThanhToan_NguoiDung ON app.ThanhToan (NguoiDungId, TrangThai, NgayTaoUtc DESC);
CREATE INDEX IX_ThanhToan_HetHan ON app.ThanhToan (ThoiGianHetHanUtc) WHERE TrangThai = 'PENDING';
GO

-- 6.2. GiaoDichThanhToan — IDEMPOTENCY
CREATE TABLE app.GiaoDichThanhToan
(
    GiaoDichId      BIGINT           IDENTITY(1,1) NOT NULL,
    ThanhToanId     UNIQUEIDENTIFIER NOT NULL,
    CongThanhToan   NVARCHAR(30)     NOT NULL,
    MaGiaoDichCong  NVARCHAR(100)    NOT NULL,
    MaDonHang       NVARCHAR(50)     NOT NULL,
    SoTien          DECIMAL(18,0)    NOT NULL,
    MaPhanHoi       NVARCHAR(20)     NULL,
    MaTrangThaiGd   NVARCHAR(20)     NULL,
    TrangThai       NVARCHAR(20)     NOT NULL,
    ChuKyHopLe      BIT              NOT NULL,
    DuLieuTho       NVARCHAR(MAX)    NULL,
    DiaChiIp        NVARCHAR(45)     NULL,
    ThoiGianNhanUtc DATETIME2(3)     NOT NULL CONSTRAINT DF_GDT_NgayNhanUtc DEFAULT SYSUTCDATETIME(),
    GhiChu          NVARCHAR(500)    NULL,
    CONSTRAINT PK_GiaoDichThanhToan PRIMARY KEY CLUSTERED (GiaoDichId),
    CONSTRAINT FK_GDT_ThanhToan FOREIGN KEY (ThanhToanId) REFERENCES app.ThanhToan(ThanhToanId),
    CONSTRAINT CK_GDT_TrangThai CHECK (TrangThai IN ('INIT','SUCCESS','FAILED','DUPLICATE','INVALID_SIGNATURE','AMOUNT_MISMATCH'))
);
GO

-- ★ Chống xử lý trùng callback ★
CREATE UNIQUE INDEX UX_GDT_Cong_MaGiaoDich
    ON app.GiaoDichThanhToan (CongThanhToan, MaGiaoDichCong);

CREATE INDEX IX_GDT_ThanhToan ON app.GiaoDichThanhToan (ThanhToanId, ThoiGianNhanUtc DESC);
CREATE INDEX IX_GDT_MaDonHang ON app.GiaoDichThanhToan (MaDonHang);
GO

USE DatSanTheThao;
GO

-- 7.1. Ve
CREATE TABLE app.Ve
(
    VeId            UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Ve_Id DEFAULT NEWSEQUENTIALID(),
    MaVe            NVARCHAR(30)     NOT NULL,
    DatSanId        UNIQUEIDENTIFIER NOT NULL,
    NguoiDungId     UNIQUEIDENTIFIER NULL,
    LoaiVe          NVARCHAR(10)     NOT NULL,
    ChiNhanhId      INT              NOT NULL,
    SanId           INT              NOT NULL,
    ThoiGianBatDauUtc  DATETIME2(3)  NOT NULL,
    ThoiGianKetThucUtc DATETIME2(3)  NOT NULL,
    TrangThai       NVARCHAR(20)     NOT NULL CONSTRAINT DF_Ve_TrangThai DEFAULT ('ACTIVE'),
    SoLuotKhachToiDa   INT           NOT NULL CONSTRAINT DF_Ve_SoLuotToiDa DEFAULT (10),
    SoLuotKhachDaDung  INT           NOT NULL CONSTRAINT DF_Ve_SoLuotDaDung DEFAULT (0),
    ThoiGianCheckInUtc  DATETIME2(3) NULL,
    ThoiGianCheckOutUtc DATETIME2(3) NULL,
    SoLanQuetOwner   INT             NOT NULL CONSTRAINT DF_Ve_SoLanQuetOwner DEFAULT (0),
    NgayTaoUtc       DATETIME2(3)    NOT NULL CONSTRAINT DF_Ve_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    NgayCapNhatUtc   DATETIME2(3)    NULL,
    NgayThuHoiUtc    DATETIME2(3)    NULL,
    LyDoThuHoi       NVARCHAR(500)   NULL,
    RowVersion       ROWVERSION      NOT NULL,
    CONSTRAINT PK_Ve PRIMARY KEY CLUSTERED (VeId),
    CONSTRAINT UQ_Ve_MaVe UNIQUE (MaVe),
    CONSTRAINT FK_Ve_DatSan    FOREIGN KEY (DatSanId)    REFERENCES app.DatSan(DatSanId),
    CONSTRAINT FK_Ve_NguoiDung FOREIGN KEY (NguoiDungId) REFERENCES app.NguoiDung(NguoiDungId),
    CONSTRAINT FK_Ve_ChiNhanh  FOREIGN KEY (ChiNhanhId)  REFERENCES app.ChiNhanh(ChiNhanhId),
    CONSTRAINT FK_Ve_San       FOREIGN KEY (SanId)       REFERENCES app.San(SanId),
    CONSTRAINT CK_Ve_LoaiVe    CHECK (LoaiVe IN ('OWNER','GUEST')),
    CONSTRAINT CK_Ve_TrangThai CHECK (TrangThai IN ('ACTIVE','USED','EXPIRED','REVOKED')),
    CONSTRAINT CK_Ve_ThoiGian  CHECK (ThoiGianKetThucUtc > ThoiGianBatDauUtc),
    CONSTRAINT CK_Ve_Quota     CHECK (SoLuotKhachDaDung >= 0
                                      AND SoLuotKhachDaDung <= SoLuotKhachToiDa
                                      AND SoLuotKhachToiDa >= 0),
    CONSTRAINT CK_Ve_LoaiVe_Quota CHECK (LoaiVe <> 'OWNER' OR SoLuotKhachToiDa = 0)
);
GO

CREATE UNIQUE INDEX UX_Ve_DatSan_Owner
    ON app.Ve (DatSanId)
    WHERE LoaiVe = 'OWNER';

CREATE INDEX IX_Ve_NguoiDung ON app.Ve (NguoiDungId, TrangThai, ThoiGianBatDauUtc DESC)
    INCLUDE (MaVe, SanId, ChiNhanhId, LoaiVe);

CREATE INDEX IX_Ve_ThoiGian_MoQr
    ON app.Ve (ThoiGianBatDauUtc, TrangThai)
    INCLUDE (DatSanId, SanId, LoaiVe);
GO

-- 7.2. MaChiaSeKhach
CREATE TABLE app.MaChiaSeKhach
(
    MaChiaSeKhachId BIGINT           IDENTITY(1,1) NOT NULL,
    VeId            UNIQUEIDENTIFIER NOT NULL,
    MaChiaSe        NVARCHAR(64)     NOT NULL,
    MaChiaSeHash    NVARCHAR(128)    NOT NULL,
    NguoiTaoId      UNIQUEIDENTIFIER NOT NULL,
    TrangThai       NVARCHAR(20)     NOT NULL CONSTRAINT DF_MCSK_TrangThai DEFAULT ('ACTIVE'),
    ThoiGianHetHanUtc DATETIME2(3)   NOT NULL,
    SoLuotTruyCap   INT              NOT NULL CONSTRAINT DF_MCSK_SoLuotTruyCap DEFAULT (0),
    SoLanCheckInThanhCong INT        NOT NULL CONSTRAINT DF_MCSK_SoLanCI DEFAULT (0),
    GioiHanCheckIn  INT              NOT NULL CONSTRAINT DF_MCSK_GioiHanCI DEFAULT (10),
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_MCSK_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    NgayThuHoiUtc   DATETIME2(3)     NULL,
    LyDoThuHoi      NVARCHAR(500)    NULL,
    RowVersion      ROWVERSION       NOT NULL,
    CONSTRAINT PK_MaChiaSeKhach PRIMARY KEY CLUSTERED (MaChiaSeKhachId),
    CONSTRAINT FK_MCSK_Ve        FOREIGN KEY (VeId)        REFERENCES app.Ve(VeId) ON DELETE CASCADE,
    CONSTRAINT FK_MCSK_NguoiTao  FOREIGN KEY (NguoiTaoId)  REFERENCES app.NguoiDung(NguoiDungId),
    CONSTRAINT CK_MCSK_TrangThai CHECK (TrangThai IN ('ACTIVE','REVOKED','EXPIRED')),
    CONSTRAINT CK_MCSK_GioiHan   CHECK (GioiHanCheckIn > 0
                                        AND SoLanCheckInThanhCong >= 0
                                        AND SoLanCheckInThanhCong <= GioiHanCheckIn)
);
GO

CREATE UNIQUE INDEX UX_MCSK_MaChiaSe ON app.MaChiaSeKhach (MaChiaSe);
CREATE INDEX IX_MCSK_Ve ON app.MaChiaSeKhach (VeId, TrangThai);
CREATE INDEX IX_MCSK_HetHan ON app.MaChiaSeKhach (ThoiGianHetHanUtc) WHERE TrangThai = 'ACTIVE';
GO

-- 7.3. LichSuTruyCapKhach
CREATE TABLE app.LichSuTruyCapKhach
(
    LichSuTruyCapKhachId BIGINT      IDENTITY(1,1) NOT NULL,
    MaChiaSeKhachId BIGINT           NOT NULL,
    VeId            UNIQUEIDENTIFIER NOT NULL,
    DatSanId        UNIQUEIDENTIFIER NOT NULL,
    LanTruyCapThu   INT              NOT NULL,
    KetQua          NVARCHAR(20)     NOT NULL,
    MaLyDo          NVARCHAR(50)     NULL,
    MaQrId          BIGINT           NULL,
    DiaChiIp        NVARCHAR(45)     NULL,
    UserAgent       NVARCHAR(500)    NULL,
    ThietBiQuet     NVARCHAR(100)    NULL,
    ThoiGianTruyCapUtc DATETIME2(3)  NOT NULL CONSTRAINT DF_LSTCK_ThoiGian DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_LichSuTruyCapKhach PRIMARY KEY CLUSTERED (LichSuTruyCapKhachId),
    CONSTRAINT FK_LSTCK_MaChiaSe FOREIGN KEY (MaChiaSeKhachId) REFERENCES app.MaChiaSeKhach(MaChiaSeKhachId),
    CONSTRAINT FK_LSTCK_Ve       FOREIGN KEY (VeId)            REFERENCES app.Ve(VeId),
    CONSTRAINT FK_LSTCK_DatSan   FOREIGN KEY (DatSanId)        REFERENCES app.DatSan(DatSanId),
    CONSTRAINT CK_LSTCK_KetQua   CHECK (KetQua IN ('ACCESS_GRANTED','ACCESS_DENIED'))
);
GO

USE DatSanTheThao;
GO

-- 8.1. MaQr
CREATE TABLE app.MaQr
(
    MaQrId          BIGINT           IDENTITY(1,1) NOT NULL,
    VeId            UNIQUEIDENTIFIER NOT NULL,
    DatSanId        UNIQUEIDENTIFIER NOT NULL,
    LoaiVe          NVARCHAR(10)     NOT NULL,
    Nonce           NVARCHAR(64)     NOT NULL,
    PhienBanToken   TINYINT          NOT NULL CONSTRAINT DF_MaQr_PhienBan DEFAULT (1),
    ThoiGianPhatHanhUtc DATETIME2(3) NOT NULL CONSTRAINT DF_MaQr_PhatHanh DEFAULT SYSUTCDATETIME(),
    ThoiGianHetHanUtc   DATETIME2(3) NOT NULL,
    ChuKyHash       NVARCHAR(128)    NULL,
    DaSuDung        BIT              NOT NULL CONSTRAINT DF_MaQr_DaSuDung DEFAULT (0),
    ThoiGianSuDungUtc DATETIME2(3)   NULL,
    DiaChiIpTao     NVARCHAR(45)     NULL,
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_MaQr_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_MaQr PRIMARY KEY CLUSTERED (MaQrId),
    CONSTRAINT FK_MaQr_Ve     FOREIGN KEY (VeId)     REFERENCES app.Ve(VeId) ON DELETE CASCADE,
    CONSTRAINT FK_MaQr_DatSan FOREIGN KEY (DatSanId) REFERENCES app.DatSan(DatSanId),
    CONSTRAINT CK_MaQr_LoaiVe CHECK (LoaiVe IN ('OWNER','GUEST')),
    CONSTRAINT CK_MaQr_HetHan CHECK (ThoiGianHetHanUtc > ThoiGianPhatHanhUtc)
);
GO

-- ★ Chống replay ★
CREATE UNIQUE INDEX UX_MaQr_Nonce ON app.MaQr (Nonce);
CREATE INDEX IX_MaQr_Ve ON app.MaQr (VeId, ThoiGianHetHanUtc DESC);
GO

-- 8.2. LichSuTruyCap
CREATE TABLE app.LichSuTruyCap
(
    LichSuTruyCapId BIGINT           IDENTITY(1,1) NOT NULL,
    MaQrId          BIGINT           NULL,
    VeId            UNIQUEIDENTIFIER NULL,
    DatSanId        UNIQUEIDENTIFIER NULL,
    NguoiDungId     UNIQUEIDENTIFIER NULL,
    LoaiVe          NVARCHAR(10)     NULL,
    KetQua          NVARCHAR(20)     NOT NULL,
    MaLyDo          NVARCHAR(50)     NULL,
    HanhDong        NVARCHAR(20)     NOT NULL,
    SanId           INT              NULL,
    ChiNhanhId      INT              NULL,
    ThietBiQuetId   INT              NULL,
    DiaChiIp        NVARCHAR(45)     NULL,
    ViDo            DECIMAL(10,7)    NULL,
    KinhDo          DECIMAL(10,7)    NULL,
    ThoiGianTruyCapUtc DATETIME2(3)  NOT NULL CONSTRAINT DF_LSTC_ThoiGian DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_LichSuTruyCap PRIMARY KEY CLUSTERED (LichSuTruyCapId),
    CONSTRAINT FK_LSTC_MaQr     FOREIGN KEY (MaQrId)        REFERENCES app.MaQr(MaQrId),
    CONSTRAINT FK_LSTC_Ve       FOREIGN KEY (VeId)          REFERENCES app.Ve(VeId),
    CONSTRAINT FK_LSTC_DatSan   FOREIGN KEY (DatSanId)      REFERENCES app.DatSan(DatSanId),
    CONSTRAINT FK_LSTC_NguoiDung FOREIGN KEY (NguoiDungId)  REFERENCES app.NguoiDung(NguoiDungId),
    CONSTRAINT FK_LSTC_San      FOREIGN KEY (SanId)         REFERENCES app.San(SanId),
    CONSTRAINT FK_LSTC_ChiNhanh FOREIGN KEY (ChiNhanhId)    REFERENCES app.ChiNhanh(ChiNhanhId),
    CONSTRAINT CK_LSTC_KetQua   CHECK (KetQua IN ('ACCESS_GRANTED','ACCESS_DENIED')),
    CONSTRAINT CK_LSTC_HanhDong CHECK (HanhDong IN ('CHECK_IN','CHECK_OUT','SCAN'))
);
GO

CREATE INDEX IX_LSTC_Ve_ThoiGian ON app.LichSuTruyCap (VeId, ThoiGianTruyCapUtc DESC);
CREATE INDEX IX_LSTC_ChiNhanh_ThoiGian ON app.LichSuTruyCap (ChiNhanhId, ThoiGianTruyCapUtc DESC);
GO

USE DatSanTheThao;
GO

CREATE TABLE app.ThietBiIoT
(
    ThietBiIoTId    INT              IDENTITY(1,1) NOT NULL,
    MaThietBi       NVARCHAR(100)    NOT NULL,
    TenThietBi      NVARCHAR(200)    NOT NULL,
    LoaiThietBi     NVARCHAR(30)     NOT NULL,
    GiaoThuc        NVARCHAR(20)     NOT NULL,
    ChiNhanhId      INT              NOT NULL,
    SanId           INT              NULL,
    DiaChiIp        NVARCHAR(45)     NULL,
    MqttTopic       NVARCHAR(300)    NULL,
    TrangThai       TINYINT          NOT NULL CONSTRAINT DF_IOT_TrangThai DEFAULT (1),
    LanKetNoiCuoiUtc DATETIME2(3)    NULL,
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_IOT_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    DaXoa           BIT              NOT NULL CONSTRAINT DF_IOT_DaXoa DEFAULT (0),
    CONSTRAINT PK_ThietBiIoT PRIMARY KEY CLUSTERED (ThietBiIoTId),
    CONSTRAINT UQ_IoT_MaThietBi UNIQUE (MaThietBi),
    CONSTRAINT FK_IoT_ChiNhanh FOREIGN KEY (ChiNhanhId) REFERENCES app.ChiNhanh(ChiNhanhId),
    CONSTRAINT FK_IoT_San      FOREIGN KEY (SanId)      REFERENCES app.San(SanId),
    CONSTRAINT CK_IoT_Loai     CHECK (LoaiThietBi IN ('CONG_TU','DEN_SAN','CAM_BIEN','TONG_DAI')),
    CONSTRAINT CK_IoT_GiaoThuc CHECK (GiaoThuc IN ('HTTP','MQTT','TCP'))
);
GO

CREATE TABLE app.NhatKyIoT
(
    NhatKyIoTId     BIGINT           IDENTITY(1,1) NOT NULL,
    ThietBiIoTId    INT              NOT NULL,
    Lenh            NVARCHAR(50)     NOT NULL,
    ThamSoJson      NVARCHAR(MAX)    NULL,
    DatSanId        UNIQUEIDENTIFIER NULL,
    VeId            UNIQUEIDENTIFIER NULL,
    KetQua          NVARCHAR(20)     NOT NULL,
    MaLoi           NVARCHAR(200)    NULL,
    ThoiGianGuiUtc  DATETIME2(3)     NOT NULL CONSTRAINT DF_NKIoT_Gui DEFAULT SYSUTCDATETIME(),
    ThoiGianPhanHoiUtc DATETIME2(3)  NULL,
    ThoiGianXuLyMs  INT              NULL,
    NguonKichHoat   NVARCHAR(30)     NOT NULL,
    CONSTRAINT PK_NhatKyIoT PRIMARY KEY CLUSTERED (NhatKyIoTId),
    CONSTRAINT FK_NKIoT_ThietBi FOREIGN KEY (ThietBiIoTId) REFERENCES app.ThietBiIoT(ThietBiIoTId),
    CONSTRAINT FK_NKIoT_DatSan  FOREIGN KEY (DatSanId)     REFERENCES app.DatSan(DatSanId),
    CONSTRAINT FK_NKIoT_Ve      FOREIGN KEY (VeId)         REFERENCES app.Ve(VeId),
    CONSTRAINT CK_NKIoT_KetQua  CHECK (KetQua IN ('SUCCESS','FAILED','TIMEOUT','PENDING'))
);
GO

USE DatSanTheThao;
GO

-- 10.1. ThongBao
CREATE TABLE app.ThongBao
(
    ThongBaoId      BIGINT           IDENTITY(1,1) NOT NULL,
    NguoiDungId     UNIQUEIDENTIFIER NOT NULL,
    LoaiThongBao    NVARCHAR(40)     NOT NULL,
    TieuDe          NVARCHAR(200)    NOT NULL,
    NoiDung         NVARCHAR(2000)   NOT NULL,
    DuLieuJson      NVARCHAR(MAX)    NULL,
    DatSanId        UNIQUEIDENTIFIER NULL,
    VeId            UNIQUEIDENTIFIER NULL,
    DaDoc           BIT              NOT NULL CONSTRAINT DF_TB_DaDoc DEFAULT (0),
    ThoiGianDocUtc  DATETIME2(3)     NULL,
    DaGuiPush       BIT              NOT NULL CONSTRAINT DF_TB_DaGuiPush DEFAULT (0),
    ThoiGianGuiPushUtc DATETIME2(3)  NULL,
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_TB_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_ThongBao PRIMARY KEY CLUSTERED (ThongBaoId),
    CONSTRAINT FK_TB_NguoiDung FOREIGN KEY (NguoiDungId) REFERENCES app.NguoiDung(NguoiDungId) ON DELETE CASCADE,
    CONSTRAINT FK_TB_DatSan    FOREIGN KEY (DatSanId)    REFERENCES app.DatSan(DatSanId),
    CONSTRAINT FK_TB_Ve        FOREIGN KEY (VeId)        REFERENCES app.Ve(VeId)
);
GO

CREATE INDEX IX_TB_NguoiDung_ChuaDoc
    ON app.ThongBao (NguoiDungId, DaDoc, NgayTaoUtc DESC);
GO

-- 10.2. DanhGia
CREATE TABLE app.DanhGia
(
    DanhGiaId       BIGINT           IDENTITY(1,1) NOT NULL,
    DatSanId        UNIQUEIDENTIFIER NOT NULL,
    SanId           INT              NOT NULL,
    NguoiDungId     UNIQUEIDENTIFIER NOT NULL,
    SoSao           TINYINT          NOT NULL,
    BinhLuan        NVARCHAR(2000)   NULL,
    TrangThai       TINYINT          NOT NULL CONSTRAINT DF_DG_TrangThai DEFAULT (1),
    PhanHoiCuaSan   NVARCHAR(2000)   NULL,
    NgayTaoUtc      DATETIME2(3)     NOT NULL CONSTRAINT DF_DG_NgayTaoUtc DEFAULT SYSUTCDATETIME(),
    NgayCapNhatUtc  DATETIME2(3)     NULL,
    CONSTRAINT PK_DanhGia PRIMARY KEY CLUSTERED (DanhGiaId),
    CONSTRAINT FK_DG_DatSan    FOREIGN KEY (DatSanId)    REFERENCES app.DatSan(DatSanId),
    CONSTRAINT FK_DG_San       FOREIGN KEY (SanId)       REFERENCES app.San(SanId),
    CONSTRAINT FK_DG_NguoiDung FOREIGN KEY (NguoiDungId) REFERENCES app.NguoiDung(NguoiDungId),
    CONSTRAINT CK_DG_SoSao     CHECK (SoSao BETWEEN 1 AND 5)
);
GO

CREATE UNIQUE INDEX UX_DG_DatSan ON app.DanhGia (DatSanId);
GO

-- 10.3. NhatKyHeThong
CREATE TABLE app.NhatKyHeThong
(
    NhatKyHeThongId BIGINT           IDENTITY(1,1) NOT NULL,
    NguoiDungId     UNIQUEIDENTIFIER NULL,
    TenDangNhap     NVARCHAR(50)     NULL,
    HanhDong        NVARCHAR(60)     NOT NULL,
    DoiTuong        NVARCHAR(50)     NULL,
    DoiTuongId      NVARCHAR(50)     NULL,
    KetQua          NVARCHAR(20)     NOT NULL,
    MaLoi           NVARCHAR(50)     NULL,
    DuLieuTruocJson NVARCHAR(MAX)    NULL,
    DuLieuSauJson   NVARCHAR(MAX)    NULL,
    DiaChiIp        NVARCHAR(45)     NULL,
    UserAgent       NVARCHAR(500)    NULL,
    RequestId       NVARCHAR(64)     NULL,
    ThoiGianUtc     DATETIME2(3)     NOT NULL CONSTRAINT DF_NKHT_ThoiGian DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_NhatKyHeThong PRIMARY KEY CLUSTERED (NhatKyHeThongId),
    CONSTRAINT FK_NKHT_NguoiDung FOREIGN KEY (NguoiDungId) REFERENCES app.NguoiDung(NguoiDungId),
    CONSTRAINT CK_NKHT_KetQua CHECK (KetQua IN ('SUCCESS','FAILED','DENIED'))
);
GO

CREATE INDEX IX_NKHT_NguoiDung_ThoiGian ON app.NhatKyHeThong (NguoiDungId, ThoiGianUtc DESC);
CREATE INDEX IX_NKHT_HanhDong_ThoiGian  ON app.NhatKyHeThong (HanhDong, ThoiGianUtc DESC);
GO

USE DatSanTheThao;
GO

CREATE OR ALTER TRIGGER app.TRG_DatSan_ChanChuyenTrangThaiSai
ON app.DatSan
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON d.DatSanId = i.DatSanId
        WHERE d.TrangThai = 'EXPIRED' AND i.TrangThai = 'PAID'
    )
    BEGIN
        THROW 51000, N'Không thể chuyển trạng thái EXPIRED sang PAID.', 1;
    END;

    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN deleted d ON d.DatSanId = i.DatSanId
        WHERE d.TrangThai IN ('CANCELLED','REFUNDED','COMPLETED')
          AND i.TrangThai NOT IN ('CANCELLED','REFUNDED','COMPLETED')
    )
    BEGIN
        THROW 51001, N'Không thể hồi sinh đơn đã kết thúc.', 1;
    END;
END;
GO

USE DatSanTheThao;
GO

-- Vai trò
INSERT INTO app.VaiTro (MaVaiTro, TenVaiTro, MoTa) VALUES
 (N'ADMIN', N'Quản trị viên', N'Toàn quyền hệ thống'),
 (N'OWNER', N'Chủ sân',       N'Quản lý chi nhánh/sân của mình'),
 (N'STAFF', N'Nhân viên',     N'Check-in/check-out tại cổng'),
 (N'USER',  N'Người dùng',    N'Khách đặt sân');
GO

-- Chi nhánh
INSERT INTO app.ChiNhanh (MaChiNhanh, TenChiNhanh, DiaChi, ViDo, KinhDo, GioMoCua, GioDongCua)
VALUES (N'TTMOC', N'Trung tâm thể thao Mộc',
        N'123 Nguyễn Văn Cừ, Quận 5, TP.HCM',
        10.7626220, 106.6601720, '06:00', '23:00');
GO

-- Loại sân
INSERT INTO app.LoaiSan (MaLoaiSan, TenLoaiSan, SoNguoiToiDa, PhutMoiSlot, ThoiLuongToiThieuPhut, ThoiLuongToiDaPhut)
VALUES (N'BONG_DA',  N'Sân bóng đá',  14, 30, 60, 180),
       (N'CAU_LONG', N'Sân cầu lông',  4, 30, 60, 120);
GO

-- Sân
DECLARE @cn INT = (SELECT ChiNhanhId FROM app.ChiNhanh WHERE MaChiNhanh = N'TTMOC');
DECLARE @bd INT = (SELECT LoaiSanId FROM app.LoaiSan WHERE MaLoaiSan = N'BONG_DA');
DECLARE @cl INT = (SELECT LoaiSanId FROM app.LoaiSan WHERE MaLoaiSan = N'CAU_LONG');

INSERT INTO app.San (ChiNhanhId, LoaiSanId, MaSan, TenSan, GiaCoBan, SucChua) VALUES
 (@cn, @bd, N'SB01',  N'Sân bóng 1',      100000, 14),
 (@cn, @bd, N'SB02',  N'Sân bóng 2',      100000, 14),
 (@cn, @bd, N'SB03',  N'Sân bóng 3',      100000, 14),
 (@cn, @cl, N'SCL01', N'Sân cầu lông 1',   80000, 4),
 (@cn, @cl, N'SCL02', N'Sân cầu lông 2',   80000, 4),
 (@cn, @cl, N'SCL03', N'Sân cầu lông 3',   80000, 4);
GO

-- Bảng giá
DECLARE @sb1 INT = (SELECT SanId FROM app.San WHERE MaSan = N'SB01');
DECLARE @scl1 INT = (SELECT SanId FROM app.San WHERE MaSan = N'SCL01');
DECLARE @cn2 INT = (SELECT ChiNhanhId FROM app.ChiNhanh WHERE MaChiNhanh = N'TTMOC');

INSERT INTO app.QuyTacGia (ChiNhanhId, SanId, LoaiSanId, TenQuyTac, ThuTrongTuan, LaNgayLe,
                           GioBatDau, GioKetThuc, GiaMoiGio, UuTien) VALUES
 (@cn2, @sb1, NULL, N'Bóng đá giờ thường',  NULL, 0, '08:00', '17:00', 100000, 10),
 (@cn2, @sb1, NULL, N'Bóng đá giờ cao điểm',NULL, 0, '17:00', '22:00', 150000, 10),
 (@cn2, @scl1, NULL,N'Cầu lông giờ thường', NULL, 0, '08:00', '17:00',  80000, 10),
 (@cn2, @scl1, NULL,N'Cầu lông cao điểm',   NULL, 0, '17:00', '22:00', 120000, 10);
GO

-- Khuyến mãi
INSERT INTO app.KhuyenMai
 (MaKhuyenMai, TenKhuyenMai, LoaiGiam, GiaTriGiam, GiamToiDa,
  DonHangToiThieu, HieuLucTuUtc, HieuLucDenUtc, SoLanMoiNguoiToiDa)
VALUES
 (N'WELCOME10', N'Giảm 10% cho người mới', 2, 10, 50000, 0,
  SYSUTCDATETIME(), DATEADD(YEAR, 1, SYSUTCDATETIME()), 1),
 (N'GIAM50K',   N'Giảm 50.000đ',           1, 50000, NULL, 200000,
  SYSUTCDATETIME(), DATEADD(MONTH, 3, SYSUTCDATETIME()), 3);
GO

-- Tiện ích
INSERT INTO app.TienIch (MaTienIch, TenTienIch) VALUES
 (N'WIFI', N'Wi-Fi miễn phí'),
 (N'GUI_XE', N'Bãi giữ xe'),
 (N'DEN_CHIEU_SANG', N'Đèn chiếu sáng'),
 (N'PHONG_THAY_DO', N'Phòng thay đồ'),
 (N'NUOC_UONG', N'Nước uống');
GO