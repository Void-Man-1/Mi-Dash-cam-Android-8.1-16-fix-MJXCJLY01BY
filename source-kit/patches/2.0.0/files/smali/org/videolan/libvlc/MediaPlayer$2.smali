.class Lorg/videolan/libvlc/MediaPlayer$2;
.super Ljava/lang/Object;
.source "MediaPlayer.java"

# interfaces
.implements Ljava/lang/Runnable;


# annotations
.annotation system Ldalvik/annotation/EnclosingMethod;
    value = Lorg/videolan/libvlc/MediaPlayer;->stop()V
.end annotation

.annotation system Ldalvik/annotation/InnerClass;
    accessFlags = 0x0
    name = null
.end annotation


# instance fields
.field final synthetic this$0:Lorg/videolan/libvlc/MediaPlayer;


# direct methods
.method constructor <init>(Lorg/videolan/libvlc/MediaPlayer;)V
    .locals 0

    .prologue
    iput-object p1, p0, Lorg/videolan/libvlc/MediaPlayer$2;->this$0:Lorg/videolan/libvlc/MediaPlayer;

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method


# virtual methods
.method public run()V
    .locals 1

    .prologue
    iget-object v0, p0, Lorg/videolan/libvlc/MediaPlayer$2;->this$0:Lorg/videolan/libvlc/MediaPlayer;

    invoke-static {v0}, Lorg/videolan/libvlc/MediaPlayer;->access$300(Lorg/videolan/libvlc/MediaPlayer;)V

    return-void
.end method
