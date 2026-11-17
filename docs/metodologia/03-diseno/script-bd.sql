-- =====================================================================
-- Carpeta Viva - DDL de PostgreSQL (esquema completo, estado de la revision 0010 = head)
-- Generado: 2026-11-17
-- Origen: metadatos SQLAlchemy (Base.metadata, app.core.models) compilados con el dialecto
--   postgresql mediante CreateTable/CreateIndex, desde backend/.
-- Por que no Alembic offline: `alembic upgrade head --sql` falla en la migracion 0009, que usa
--   sa.inspect(op.get_bind()) y en modo offline la conexion es un MockConnection sin
--   inspeccion (NoInspectionAvailable). Las migraciones 0001 a 0008 si generan SQL offline.
-- Referencia canonica para instalar: `alembic upgrade head` (migrations/versions/0001..0010).
--   Este archivo es documentacion de diseno; NO sustituye a Alembic en un despliegue.
-- Contenido: extensiones, tablas, restricciones, indices y semillas de catalogos
--   (catalogos_opciones, de la migracion 0009). Sin datos de personas.
-- Nota: la tabla de auditoria NO esta particionada por fecha todavia (pendiente, ver
--   docs/metodologia/06-despliegue/paquetes-y-servidor.md).
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE menores (
	nombres VARCHAR(120) NOT NULL, 
	apellidos VARCHAR(120) NOT NULL, 
	fecha_nacimiento DATE NOT NULL, 
	genero VARCHAR(20), 
	tipo_documento VARCHAR(30), 
	numero_documento VARCHAR(50), 
	estado_actual VARCHAR(30) NOT NULL, 
	version INTEGER NOT NULL, 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_menores_tipo_documento CHECK (tipo_documento IS NULL OR tipo_documento IN ('registro_civil', 'tarjeta_identidad', 'cedula', 'pasaporte', 'sin_documento')), 
	CONSTRAINT ck_menores_estado_actual CHECK (estado_actual IN ('activo', 'egresado', 'evadido', 'fallecido'))
);

CREATE UNIQUE INDEX ix_menores_numero_documento ON menores (numero_documento) WHERE numero_documento IS NOT NULL;

CREATE TABLE zonas (
	nombre VARCHAR(100) NOT NULL, 
	descripcion VARCHAR(255), 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	UNIQUE (nombre)
);

CREATE TABLE menores_familiares (
	menor_id UUID NOT NULL, 
	parentesco VARCHAR(20) NOT NULL, 
	nombres VARCHAR(120), 
	numero_identificacion VARCHAR(50), 
	telefono VARCHAR(30), 
	direccion VARCHAR(255), 
	estado_vital VARCHAR(20) NOT NULL, 
	observaciones TEXT, 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_menores_familiares_parentesco CHECK (parentesco IN ('padre', 'madre', 'otro')), 
	CONSTRAINT ck_menores_familiares_estado_vital CHECK (estado_vital IN ('vivo', 'fallecido', 'desconocido')), 
	FOREIGN KEY(menor_id) REFERENCES menores (id)
);

CREATE INDEX ix_menores_familiares_menor_id ON menores_familiares (menor_id);

CREATE TABLE usuarios (
	email VARCHAR(255) NOT NULL, 
	password_hash VARCHAR(255) NOT NULL, 
	rol VARCHAR(30) NOT NULL, 
	activo BOOLEAN NOT NULL, 
	zona_id UUID, 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(zona_id) REFERENCES zonas (id)
);

CREATE UNIQUE INDEX ix_usuarios_email ON usuarios (email);

CREATE TABLE alertas (
	tipo VARCHAR(30) NOT NULL, 
	menor_id UUID NOT NULL, 
	origen VARCHAR(20) NOT NULL, 
	generada_por UUID, 
	descripcion VARCHAR(255) NOT NULL, 
	detalle JSON, 
	estado VARCHAR(20) NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	id UUID NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_alertas_tipo CHECK (tipo IN ('evasion', 'visita_vencida', 'documento_faltante', 'indexacion_pendiente')), 
	CONSTRAINT ck_alertas_origen CHECK (origen IN ('manual', 'automatica')), 
	CONSTRAINT ck_alertas_estado CHECK (estado IN ('activa', 'cerrada')), 
	FOREIGN KEY(menor_id) REFERENCES menores (id), 
	FOREIGN KEY(generada_por) REFERENCES usuarios (id)
);

CREATE INDEX ix_alertas_menor_id ON alertas (menor_id);

CREATE TABLE auditoria_accesos (
	usuario_id UUID, 
	accion VARCHAR(60) NOT NULL, 
	recurso VARCHAR(255), 
	menor_id UUID, 
	ip VARCHAR(64), 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	id UUID NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(usuario_id) REFERENCES usuarios (id)
);

CREATE INDEX ix_auditoria_accesos_accion ON auditoria_accesos (accion);

CREATE INDEX ix_auditoria_accesos_created_at ON auditoria_accesos (created_at);

CREATE INDEX ix_auditoria_accesos_menor_id ON auditoria_accesos (menor_id);

CREATE INDEX ix_auditoria_accesos_usuario_id ON auditoria_accesos (usuario_id);

CREATE TABLE catalogos_opciones (
	grupo VARCHAR(60) NOT NULL, 
	valor VARCHAR(100) NOT NULL, 
	etiqueta VARCHAR(200) NOT NULL, 
	orden INTEGER NOT NULL, 
	activo BOOLEAN NOT NULL, 
	seccion_acceso VARCHAR(20), 
	creado_en TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	actualizado_en TIMESTAMP WITH TIME ZONE, 
	actualizado_por UUID, 
	id UUID NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT uq_catalogos_opciones_grupo_valor UNIQUE (grupo, valor), 
	FOREIGN KEY(actualizado_por) REFERENCES usuarios (id)
);

CREATE INDEX ix_catalogos_opciones_grupo ON catalogos_opciones (grupo);

CREATE TABLE citas (
	menor_id UUID NOT NULL, 
	tipo VARCHAR(30) NOT NULL, 
	fecha_hora TIMESTAMP WITH TIME ZONE NOT NULL, 
	lugar VARCHAR(255), 
	notas TEXT, 
	estado VARCHAR(20) NOT NULL, 
	registrado_por UUID NOT NULL, 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_citas_tipo CHECK (tipo IN ('medica', 'psicosocial', 'reunion_familia', 'otro')), 
	CONSTRAINT ck_citas_estado CHECK (estado IN ('pendiente', 'cumplida', 'no_asistio')), 
	FOREIGN KEY(menor_id) REFERENCES menores (id), 
	FOREIGN KEY(registrado_por) REFERENCES usuarios (id)
);

CREATE INDEX ix_citas_menor_id ON citas (menor_id);

CREATE TABLE configuracion_sistema (
	clave VARCHAR(100) NOT NULL, 
	valor TEXT, 
	actualizado_en TIMESTAMP WITH TIME ZONE, 
	actualizado_por UUID, 
	PRIMARY KEY (clave), 
	FOREIGN KEY(actualizado_por) REFERENCES usuarios (id)
);

CREATE TABLE expedientes_archivo (
	menor_id UUID NOT NULL, 
	estado VARCHAR(20) NOT NULL, 
	archivado_en TIMESTAMP WITH TIME ZONE, 
	archivado_por UUID, 
	motivo VARCHAR(255), 
	zona_id UUID, 
	paquete_referencia VARCHAR(255), 
	paquete_hash VARCHAR(64), 
	destino VARCHAR(255) NOT NULL, 
	enviado_en TIMESTAMP WITH TIME ZONE, 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_expedientes_archivo_estado CHECK (estado IN ('activo', 'archivado')), 
	FOREIGN KEY(menor_id) REFERENCES menores (id), 
	FOREIGN KEY(archivado_por) REFERENCES usuarios (id), 
	FOREIGN KEY(zona_id) REFERENCES zonas (id)
);

CREATE UNIQUE INDEX ix_expedientes_archivo_menor_id ON expedientes_archivo (menor_id);

CREATE INDEX ix_expedientes_archivo_zona_id ON expedientes_archivo (zona_id);

CREATE TABLE informes_generados (
	usuario_id UUID NOT NULL, 
	nivel VARCHAR(20) NOT NULL, 
	filtros JSONB NOT NULL, 
	formato VARCHAR(10) NOT NULL, 
	referencia_archivo VARCHAR(255), 
	generado_en TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	id UUID NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_informes_generados_nivel CHECK (nivel IN ('general', 'zona', 'menor', 'madre')), 
	CONSTRAINT ck_informes_generados_formato CHECK (formato IN ('json', 'pdf', 'csv')), 
	FOREIGN KEY(usuario_id) REFERENCES usuarios (id)
);

CREATE INDEX ix_informes_generados_usuario_id ON informes_generados (usuario_id);

CREATE TABLE madres_sustitutas (
	usuario_id UUID, 
	nombres VARCHAR(120) NOT NULL, 
	apellidos VARCHAR(120) NOT NULL, 
	numero_identificacion VARCHAR(30) NOT NULL, 
	direccion VARCHAR(255), 
	telefono VARCHAR(30), 
	estado_certificacion VARCHAR(30) NOT NULL, 
	firma_ref VARCHAR(255), 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	UNIQUE (usuario_id), 
	FOREIGN KEY(usuario_id) REFERENCES usuarios (id), 
	UNIQUE (numero_identificacion)
);

CREATE TABLE menores_history (
	menor_id UUID NOT NULL, 
	version INTEGER NOT NULL, 
	nombres VARCHAR(120) NOT NULL, 
	apellidos VARCHAR(120) NOT NULL, 
	fecha_nacimiento DATE NOT NULL, 
	genero VARCHAR(20), 
	tipo_documento VARCHAR(30), 
	numero_documento VARCHAR(50), 
	estado_actual VARCHAR(30) NOT NULL, 
	cambiado_por UUID, 
	motivo VARCHAR(255), 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	id UUID NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(menor_id) REFERENCES menores (id), 
	FOREIGN KEY(cambiado_por) REFERENCES usuarios (id)
);

CREATE INDEX ix_menores_history_menor_id ON menores_history (menor_id);

CREATE TABLE permisos_expediente (
	menor_id UUID NOT NULL, 
	seccion VARCHAR(20) NOT NULL, 
	usuario_id UUID NOT NULL, 
	otorgado_por UUID NOT NULL, 
	activo BOOLEAN NOT NULL, 
	notas VARCHAR(255), 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT uq_permisos_expediente_menor_seccion_usuario UNIQUE (menor_id, seccion, usuario_id), 
	CONSTRAINT ck_permisos_expediente_seccion CHECK (seccion IN ('familia', 'salud', 'psicosocial')), 
	FOREIGN KEY(menor_id) REFERENCES menores (id), 
	FOREIGN KEY(usuario_id) REFERENCES usuarios (id), 
	FOREIGN KEY(otorgado_por) REFERENCES usuarios (id)
);

CREATE INDEX ix_permisos_expediente_menor_id ON permisos_expediente (menor_id);

CREATE INDEX ix_permisos_expediente_usuario_id ON permisos_expediente (usuario_id);

CREATE TABLE profesionales (
	usuario_id UUID, 
	nombres VARCHAR(120) NOT NULL, 
	apellidos VARCHAR(120) NOT NULL, 
	cargo VARCHAR(40) NOT NULL, 
	especialidad VARCHAR(120), 
	numero_registro VARCHAR(60), 
	telefono VARCHAR(30), 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	UNIQUE (usuario_id), 
	FOREIGN KEY(usuario_id) REFERENCES usuarios (id)
);

CREATE TABLE reportes (
	menor_id UUID NOT NULL, 
	autor_id UUID NOT NULL, 
	tipo_autor VARCHAR(30) NOT NULL, 
	tipo_reporte VARCHAR(60) NOT NULL, 
	contenido JSONB NOT NULL, 
	referencia_archivo VARCHAR(255), 
	version INTEGER NOT NULL, 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(menor_id) REFERENCES menores (id), 
	FOREIGN KEY(autor_id) REFERENCES usuarios (id)
);

CREATE INDEX ix_reportes_menor_id ON reportes (menor_id);

CREATE TABLE alertas_destinatarios (
	alerta_id UUID NOT NULL, 
	usuario_id UUID NOT NULL, 
	visto_en TIMESTAMP WITH TIME ZONE, 
	notificado_en TIMESTAMP WITH TIME ZONE, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	id UUID NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT uq_alertas_destinatarios_alerta_usuario UNIQUE (alerta_id, usuario_id), 
	FOREIGN KEY(alerta_id) REFERENCES alertas (id), 
	FOREIGN KEY(usuario_id) REFERENCES usuarios (id)
);

CREATE INDEX ix_alertas_destinatarios_alerta_id ON alertas_destinatarios (alerta_id);

CREATE INDEX ix_alertas_destinatarios_usuario_id ON alertas_destinatarios (usuario_id);

CREATE TABLE hogares_sustitutos (
	zona_id UUID NOT NULL, 
	madre_id UUID, 
	capacidad_maxima INTEGER NOT NULL, 
	fecha_habilitacion DATE, 
	estado VARCHAR(30) NOT NULL, 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(zona_id) REFERENCES zonas (id), 
	FOREIGN KEY(madre_id) REFERENCES madres_sustitutas (id)
);

CREATE INDEX ix_hogares_sustitutos_zona_id ON hogares_sustitutos (zona_id);

CREATE TABLE menores_profesionales (
	menor_id UUID NOT NULL, 
	profesional_id UUID NOT NULL, 
	rol_asignado VARCHAR(40) NOT NULL, 
	id UUID NOT NULL, 
	PRIMARY KEY (id), 
	UNIQUE (menor_id, profesional_id, rol_asignado), 
	FOREIGN KEY(menor_id) REFERENCES menores (id), 
	FOREIGN KEY(profesional_id) REFERENCES profesionales (id)
);

CREATE INDEX ix_menores_profesionales_menor_id ON menores_profesionales (menor_id);

CREATE INDEX ix_menores_profesionales_profesional_id ON menores_profesionales (profesional_id);

CREATE TABLE alimentos_checklist_items (
	hogar_id UUID NOT NULL, 
	descripcion VARCHAR(255) NOT NULL, 
	perecedero BOOLEAN NOT NULL, 
	unidad_por_defecto VARCHAR(20), 
	activo BOOLEAN NOT NULL, 
	creado_por UUID NOT NULL, 
	creado_en TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	id UUID NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(hogar_id) REFERENCES hogares_sustitutos (id), 
	FOREIGN KEY(creado_por) REFERENCES usuarios (id)
);

CREATE INDEX ix_alimentos_checklist_items_hogar_id ON alimentos_checklist_items (hogar_id);

CREATE TABLE asignaciones (
	menor_id UUID NOT NULL, 
	hogar_id UUID NOT NULL, 
	fecha_inicio DATE NOT NULL, 
	fecha_fin DATE, 
	estado VARCHAR(30) NOT NULL, 
	version INTEGER NOT NULL, 
	tipo_movimiento VARCHAR(20) NOT NULL, 
	acta_referencia VARCHAR(255), 
	motivo VARCHAR(255), 
	registrado_por UUID, 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_asignaciones_tipo_movimiento CHECK (tipo_movimiento IN ('ingreso', 'traslado', 'egreso')), 
	FOREIGN KEY(menor_id) REFERENCES menores (id), 
	FOREIGN KEY(hogar_id) REFERENCES hogares_sustitutos (id), 
	FOREIGN KEY(registrado_por) REFERENCES usuarios (id)
);

CREATE INDEX ix_asignaciones_hogar_id ON asignaciones (hogar_id);

CREATE INDEX ix_asignaciones_menor_id ON asignaciones (menor_id);

CREATE TABLE documentos (
	menor_id UUID, 
	hogar_id UUID, 
	categoria VARCHAR(60) NOT NULL, 
	titulo VARCHAR(255) NOT NULL, 
	estado_flujo VARCHAR(30) NOT NULL, 
	version INTEGER NOT NULL, 
	referencia_archivo VARCHAR(255), 
	hash_sha256 VARCHAR(64), 
	sensible BOOLEAN NOT NULL, 
	creado_por UUID NOT NULL, 
	nombre_original VARCHAR(255) NOT NULL, 
	mime_type VARCHAR(100) NOT NULL, 
	tamanio_bytes INTEGER NOT NULL, 
	revisado_por UUID, 
	revisado_en TIMESTAMP WITH TIME ZONE, 
	motivo_devolucion VARCHAR(255), 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_documentos_estado_flujo CHECK (estado_flujo IN ('borrador', 'en_revision', 'aprobado', 'devuelto')), 
	FOREIGN KEY(menor_id) REFERENCES menores (id), 
	FOREIGN KEY(hogar_id) REFERENCES hogares_sustitutos (id), 
	FOREIGN KEY(creado_por) REFERENCES usuarios (id), 
	FOREIGN KEY(revisado_por) REFERENCES usuarios (id)
);

CREATE INDEX ix_documentos_hogar_id ON documentos (hogar_id);

CREATE INDEX ix_documentos_menor_id ON documentos (menor_id);

CREATE INDEX ix_documentos_menor_id_categoria ON documentos (menor_id, categoria);

CREATE TABLE hogar_convivientes (
	hogar_id UUID NOT NULL, 
	nombres VARCHAR(120) NOT NULL, 
	relacion_con_madre VARCHAR(60) NOT NULL, 
	fecha_desde DATE, 
	observaciones VARCHAR(255), 
	activo BOOLEAN NOT NULL, 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(hogar_id) REFERENCES hogares_sustitutos (id)
);

CREATE INDEX ix_hogar_convivientes_hogar_id ON hogar_convivientes (hogar_id);

CREATE TABLE hogar_red_apoyo (
	hogar_id UUID NOT NULL, 
	nombres VARCHAR(120) NOT NULL, 
	relacion VARCHAR(60) NOT NULL, 
	telefono VARCHAR(30), 
	observaciones VARCHAR(255), 
	activo BOOLEAN NOT NULL, 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(hogar_id) REFERENCES hogares_sustitutos (id)
);

CREATE INDEX ix_hogar_red_apoyo_hogar_id ON hogar_red_apoyo (hogar_id);

CREATE TABLE ia_consultas (
	usuario_id UUID NOT NULL, 
	pregunta TEXT NOT NULL, 
	menor_id UUID, 
	hogar_id UUID, 
	fragmentos_usados JSONB NOT NULL, 
	respuesta TEXT NOT NULL, 
	modelo VARCHAR(100) NOT NULL, 
	proveedor VARCHAR(50) NOT NULL, 
	anonimizado BOOLEAN NOT NULL, 
	sin_resultado BOOLEAN NOT NULL, 
	duracion_ms INTEGER, 
	creado_en TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	id UUID NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(usuario_id) REFERENCES usuarios (id), 
	FOREIGN KEY(menor_id) REFERENCES menores (id), 
	FOREIGN KEY(hogar_id) REFERENCES hogares_sustitutos (id)
);

CREATE INDEX ix_ia_consultas_hogar_id ON ia_consultas (hogar_id);

CREATE INDEX ix_ia_consultas_menor_id ON ia_consultas (menor_id);

CREATE INDEX ix_ia_consultas_usuario_id ON ia_consultas (usuario_id);

CREATE TABLE inventario_items (
	hogar_id UUID NOT NULL, 
	tipo VARCHAR(20) NOT NULL, 
	descripcion VARCHAR(255) NOT NULL, 
	cantidad INTEGER NOT NULL, 
	estado VARCHAR(20) NOT NULL, 
	registrado_por UUID NOT NULL, 
	recibido BOOLEAN DEFAULT 'true' NOT NULL, 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_inventario_items_tipo CHECK (tipo IN ('cama', 'mueble', 'otro')), 
	CONSTRAINT ck_inventario_items_estado CHECK (estado IN ('bueno', 'regular', 'malo', 'retirado')), 
	FOREIGN KEY(hogar_id) REFERENCES hogares_sustitutos (id), 
	FOREIGN KEY(registrado_por) REFERENCES usuarios (id)
);

CREATE INDEX ix_inventario_items_hogar_id ON inventario_items (hogar_id);

CREATE TABLE alimentos_items (
	hogar_id UUID NOT NULL, 
	descripcion VARCHAR(255) NOT NULL, 
	fecha_ingreso DATE NOT NULL, 
	perecedero BOOLEAN NOT NULL, 
	fecha_vencimiento DATE, 
	cantidad FLOAT NOT NULL, 
	unidad VARCHAR(20), 
	consumido BOOLEAN NOT NULL, 
	registrado_por UUID NOT NULL, 
	checklist_item_id UUID, 
	id UUID NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(hogar_id) REFERENCES hogares_sustitutos (id), 
	FOREIGN KEY(registrado_por) REFERENCES usuarios (id), 
	FOREIGN KEY(checklist_item_id) REFERENCES alimentos_checklist_items (id)
);

CREATE INDEX ix_alimentos_items_hogar_id ON alimentos_items (hogar_id);

CREATE TABLE asignaciones_history (
	asignacion_id UUID NOT NULL, 
	version INTEGER NOT NULL, 
	menor_id UUID NOT NULL, 
	hogar_id UUID NOT NULL, 
	fecha_inicio DATE NOT NULL, 
	fecha_fin DATE, 
	estado VARCHAR(30) NOT NULL, 
	tipo_movimiento VARCHAR(20) NOT NULL, 
	acta_referencia VARCHAR(255), 
	motivo VARCHAR(255), 
	cambiado_por UUID, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	id UUID NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(asignacion_id) REFERENCES asignaciones (id), 
	FOREIGN KEY(menor_id) REFERENCES menores (id), 
	FOREIGN KEY(hogar_id) REFERENCES hogares_sustitutos (id), 
	FOREIGN KEY(cambiado_por) REFERENCES usuarios (id)
);

CREATE INDEX ix_asignaciones_history_asignacion_id ON asignaciones_history (asignacion_id);

CREATE INDEX ix_asignaciones_history_menor_id ON asignaciones_history (menor_id);

CREATE TABLE documentos_versiones (
	documento_id UUID NOT NULL, 
	version INTEGER NOT NULL, 
	referencia_archivo VARCHAR(255), 
	hash_sha256 VARCHAR(64), 
	nombre_original VARCHAR(255), 
	mime_type VARCHAR(100), 
	tamanio_bytes INTEGER, 
	estado_flujo VARCHAR(30) NOT NULL, 
	creado_por UUID, 
	revisado_por UUID, 
	motivo_devolucion VARCHAR(255), 
	comprimida BOOLEAN DEFAULT 'false' NOT NULL, 
	created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	id UUID NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(documento_id) REFERENCES documentos (id), 
	FOREIGN KEY(creado_por) REFERENCES usuarios (id), 
	FOREIGN KEY(revisado_por) REFERENCES usuarios (id)
);

CREATE INDEX ix_documentos_versiones_documento_id ON documentos_versiones (documento_id);

CREATE TABLE fragmentos_documento (
	documento_id UUID, 
	reporte_id UUID, 
	menor_id UUID, 
	hogar_id UUID, 
	seccion VARCHAR(20), 
	version_documento INTEGER NOT NULL, 
	orden INTEGER NOT NULL, 
	texto TEXT NOT NULL, 
	embedding VECTOR(384) NOT NULL, 
	modelo_embedding VARCHAR(100) NOT NULL, 
	creado_en TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	id UUID NOT NULL, 
	PRIMARY KEY (id), 
	CONSTRAINT ck_fragmentos_documento_documento_xor_reporte CHECK ((documento_id IS NOT NULL AND reporte_id IS NULL) OR (documento_id IS NULL AND reporte_id IS NOT NULL)), 
	CONSTRAINT ck_fragmentos_documento_seccion CHECK (seccion IS NULL OR seccion IN ('familia', 'salud', 'psicosocial')), 
	CONSTRAINT uq_fragmentos_documento_documento_version_orden UNIQUE (documento_id, version_documento, orden), 
	CONSTRAINT uq_fragmentos_documento_reporte_version_orden UNIQUE (reporte_id, version_documento, orden), 
	FOREIGN KEY(documento_id) REFERENCES documentos (id), 
	FOREIGN KEY(reporte_id) REFERENCES reportes (id), 
	FOREIGN KEY(menor_id) REFERENCES menores (id), 
	FOREIGN KEY(hogar_id) REFERENCES hogares_sustitutos (id)
);

CREATE INDEX ix_fragmentos_documento_documento_id ON fragmentos_documento (documento_id);

CREATE INDEX ix_fragmentos_documento_embedding_hnsw ON fragmentos_documento USING hnsw (embedding vector_cosine_ops);

CREATE INDEX ix_fragmentos_documento_hogar_id ON fragmentos_documento (hogar_id);

CREATE INDEX ix_fragmentos_documento_menor_id ON fragmentos_documento (menor_id);

CREATE INDEX ix_fragmentos_documento_reporte_id ON fragmentos_documento (reporte_id);

CREATE TABLE inventario_item_fotos (
	item_id UUID NOT NULL, 
	referencia_archivo VARCHAR(255) NOT NULL, 
	mime_type VARCHAR(100) NOT NULL, 
	tamanio_bytes INTEGER NOT NULL, 
	subido_por UUID NOT NULL, 
	creado_en TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL, 
	declaracion_sin_menores BOOLEAN DEFAULT 'true' NOT NULL, 
	oculta BOOLEAN DEFAULT 'false' NOT NULL, 
	id UUID NOT NULL, 
	PRIMARY KEY (id), 
	FOREIGN KEY(item_id) REFERENCES inventario_items (id), 
	FOREIGN KEY(subido_por) REFERENCES usuarios (id)
);

CREATE INDEX ix_inventario_item_fotos_item_id ON inventario_item_fotos (item_id);

-- Semillas de catalogos (migracion 0009, ADR-0013)
INSERT INTO catalogos_opciones (id, grupo, valor, etiqueta, orden, seccion_acceso) VALUES
  (gen_random_uuid(), 'categoria_documento_menor', 'identidad', 'Identidad', 0, NULL),
  (gen_random_uuid(), 'categoria_documento_menor', 'salud', 'Salud', 1, 'salud'),
  (gen_random_uuid(), 'categoria_documento_menor', 'psicosocial', 'Psicosocial', 2, 'psicosocial'),
  (gen_random_uuid(), 'categoria_documento_menor', 'educacion', 'Educación', 3, NULL),
  (gen_random_uuid(), 'categoria_documento_menor', 'familia_red_apoyo', 'Familia y red de apoyo', 4, 'familia'),
  (gen_random_uuid(), 'categoria_documento_menor', 'actas_traslados', 'Actas de traslado', 5, NULL),
  (gen_random_uuid(), 'categoria_documento_menor', 'otros', 'Otros', 6, NULL),
  (gen_random_uuid(), 'categoria_documento_hogar', 'madre_habilitacion', 'Habilitación de la madre', 0, NULL),
  (gen_random_uuid(), 'categoria_documento_hogar', 'otros', 'Otros', 1, NULL);

-- Control de versiones de Alembic (solo si se carga este archivo en lugar de migrar):
-- CREATE TABLE alembic_version (version_num VARCHAR(32) NOT NULL PRIMARY KEY);
-- INSERT INTO alembic_version VALUES ('0010');
